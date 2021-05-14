# clause-boundary
A quite simple, prehistoric
rule-based clause boundary detector for Hungarian
in perl with an overly complicated software architecture.

According to [Kalivoda Ági](https://github.com/kagnes)
_"it works very well"._ (2021-05-14)

Published evaluation shows:
precision = 83.6 and recall = 86.5


## usage

Requirement: `perl`.

```bash
make FILE=vertical
```

which takes the provided sample file `vertical`,
and creates a clause-per-line output: `vertical.clause`.

Which should be identical with `vertical.clause.BACKUP`.


## input format

For the required input format see file `vertical`.

It is an ancient HNC1 inner XML format
which contains `tsv` inside of `<s>` (sentence) tags.
1st column = wordform;
2nd column = lemma;
3rd column = Hungarian morphological annotation by Humor
as it is in HNC1;
4th column to be ignored.
Additional bonus: file encoding is `iso-8859-2`.
Sorry...


## citation

If you might use it, please refer to the following paper:

_Sass Bálint: Igei vonzatkeretek az MNSZ tagmondataiban. In: Alexin Z., Csendes D. (szerk.): MSZNY2006, IV. Magyar Számítógépes Nyelvészeti Konferencia, SZTE, Szeged, 2006., p. 15-21._

```
@inproceedings{ sass2006igei,
  author = "Sass, B{\'a}lint",
  title = "Igei vonzatkeretek az {MNSZ} tagmondataiban",
  booktitle = "Alexin Z., Csendes D.\ (szerk.): {IV}.\ Magyar Sz{\'a}m{\'\i}t{\'o}g{\'e}pes Nyelv{\'e}szeti Konferencia ({MSZNY}2006)",
  year = 2006,
  pages = "15--21",
  address = "Szeged",
  url = "http://www.nytud.hu/oszt/korpusz/resources/sb_vktagm.doc"
}
```

