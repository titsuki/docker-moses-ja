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
$ perl -CSD -ple 'my @a=split(" \\|\\|\\| "); $a[0] =~ s/^ +//; $a[0] =~ s/ +$//; $a[0] =~ s/ +//g; $_=join(" ",split(//,$a[0]))' < titles.txt > train.ja
$ perl -CSD -ple 'my @a=split(" \\|\\|\\| "); $a[1] =~ s/^ +//; $a[1] =~ s/ +$//; $a[1] =~ s/ +/ /g; $_=$a[1]' < titles.txt > train.en
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
```

### 5. Train Phrase based model

+ TBD

### 6. Train OSM

+ TBD

### 7. Predict

+ TBD
