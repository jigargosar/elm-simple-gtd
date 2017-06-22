testwatch:
	fswatch src/*.elm test/*.elm | \
	while read f; do \
	    echo; echo; \
	    echo $$f; \
	    (cd test; elm make Test.elm --yes); \
	done

testbrowser:
	browser-sync start --server --files test/index.html --startPath test/index.html

documentation.json: src/ParseInt.elm
	elm make --docs=documentation.json
