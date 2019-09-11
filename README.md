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

+ TBD

### 4. Train Phrase based model

+ TBD

### 5. Train OSM

+ TBD

### 6. Predict

+ TBD
