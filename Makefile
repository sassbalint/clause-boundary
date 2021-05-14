
all: run

FILE=vertical

run:
	./clause2.pl -v $(FILE) -p > $(FILE).clause

