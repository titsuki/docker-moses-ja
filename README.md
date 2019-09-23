# docker-moses-ja

## A Tutorial

### 1. Build and run docker image

```
# sudo docker build . -t moses
# sudo docker run -it -p 8080:8080 moses
```

### 2. Get a ja-en corpus


Commands:
```
$ cd /home/moses/wikipedia-parallel-titles
$ wget http://dumps.wikimedia.org/jawiki/20190901/jawiki-20190901-page.sql.gz
$ wget http://dumps.wikimedia.org/jawiki/20190901/jawiki-20190901-langlinks.sql.gz
$ ./build-corpus.sh en jawiki-20190901 > titles.txt
```

The resulting ja-en titles are:
```
...
1,3,5-トリアジン ||| 1,3,5-Triazine
1,3,5-トリオキサン ||| 1,3,5-Trioxane
1,3,5-トリオキサントリオン ||| 1,3,5-Trioxanetrione
1,3,5-トリチアン ||| 1,3,5-Trithiane
...
```

### 3. Tokenize the corpus

+ Tokenize the corpus
  + where `-CSD` is a option to avoid byte-level token splitting
     + (e.g., kanji character "笑" is composed of four bytes, so a byte-level token splitter generates the sequence of E7 AC 91 20; this is not a result we want.) 
```
$ perl -CSD -ple 'my @a=split(" \\|\\|\\| "); $a[0] =~ s/^ +//; $a[0] =~ s/ +$//; $a[0] =~ s/ +//g; $a[0] =~ s/</&lt/g; $a[0] =~ s/>/&gt/g; $_=join(" ",split(//,$a[0]))' < titles.txt > train.ja
$ perl -CSD -ple 'my @a=split(" \\|\\|\\| "); $a[1] =~ s/^ +//; $a[1] =~ s/ +$//; $a[1] =~ s/ +/ /g; $a[1] =~ s/</&lt/g; $a[1] =~ s/>/&gt/g; $_=$a[1]' < titles.txt > train.en
```

+ Check tokenized corpus
```
$ export LESSCHARSET="utf-8"
$ less train.ja
$ less train.en
```

+ Create fast-align format data
```
$ paste -d$'\t' train.en train.ja | perl -nple 's/\t/ \|\|\| /' > text.en-ja
$ paste -d$'\t' train.ja train.en | perl -nple 's/\t/ \|\|\| /' > text.ja-en
```

### 4. Create alignment

```
$ ../fast_align/fast_align -i text.en-ja -d -o -v > forward.align
$ ../fast_align/fast_align -i text.ja-en -d -o -v > backward.align
$ ../fast_align/atools -i forward.align -j backward.align -c grow-diag-final > aligned.grow-diag-final
$ cd /home/moses/mosesdecoder
$ mkdir model && cd model && ln -s /home/moses/wikipedia-parallel-titles/aligned.grow-diag-final
```

### 5. Train OSM

+ TBD
```
$ cd /home/moses/mosesdecoder
$ ln -s /home/moses/wikipedia-parallel-titles/train.ja
$ ln -s /home/moses/wikipedia-parallel-titles/train.en
$ ln -s /home/moses/wikipedia-parallel-titles/forward.align
$ ./scripts/OSM/OSM-Train.perl --corpus-f /home/moses/mosesdecoder/train.en \
--corpus-e /home/moses/mosesdecoder/train.ja \
--alignment /home/moses/mosesdecoder/forward.align \
--moses-src-dir /home/moses/mosesdecoder \
--out-dir osm-model
```

### 6. Train Phrase based model

+ The `--first-step 4` option skips the alignment process by GIZA++
```
$ cd /home/moses/mosesdecoder
$ ./bin/lmplz -S 80% -o 5 --discount_fallback < train.ja > train.ja.arpa
$ ./scripts/training/train-model.perl --external-bin-dir /home/moses/mosesdecoder/tools/ --corpus train --f en --e ja --lm 0:5:/home/moses/mosesdecoder/train.ja.arpa --osm-model /home/moses/mosesdecoder/osm-model/operationLM.bin --first-step 4
```

### 7. Predict

+ Create a webapp skelton
```
$ cpan Mojolicious::Lite
$ sudo apt-get libsoap-lite-perl #TODO: Dockerfile should contain this module
$ cd /home/moses/mosesdecoder
$ mkdir mojo && cd mojo
$ mojo generate lite_app
```

+ Write myapp.pl as:
```
#!/usr/bin/env perl
use Mojolicious::Lite;
use XMLRPC::Lite;
use IPC::Open2;
use Encode qw/encode decode/;

my $port = 8090;
my $url = "http://localhost:${port}/RPC2";
my $MOSES = '/home/moses/mosesdecoder/bin/moses2';
my $MOSES_INI = '/home/moses/mosesdecoder/model/moses.ini';
my ($read_fh, $write_fh);
open2($read_fh, $write_fh, $MOSES, "-config", $MOSES_INI, "--server", "--server-port", $port);

get '/:q' => sub {
  my $c = shift;
  my $q = $c->param('q');
  my $encoded = SOAP::Data->type(string => encode("utf8", $q));
  my %param = ("text" => $encoded, "align" => "true", "report-all-factors" => "true");
  my $proxy = XMLRPC::Lite->proxy($url);
  my $result = $proxy->call("translate", \%param)->result;
  $c->render(json => $result);
};

app->start;

```

+ Run a SMT server as:
```
$ ./myapp.pl daemon -m production -l http://*:8080
```

+ Access http://localhost:8080/
  + e.g., http://localhost:8080/hello
