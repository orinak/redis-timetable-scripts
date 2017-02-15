watch-test: node_modules/.bin/ava
	$< test/*.spec.js -vsw

test: node_modules/.bin/ava
	$< test/*.spec.js -vs

node_modules/.bin/%: node_modules
	@echo $@

node_modules: package.json
	npm install


clean:
	rm -rf node_modules


.PHONY: test clean