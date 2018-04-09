all: cleanup build

quickstart: deps cleanup build config validate

deps:
	@echo ""
	@echo "*********************************************************"
	@echo "***** Checking the system for required software ... *****"
	@echo "*********************************************************"
	./deps.sh

cleanup:
	@echo ""
	@echo "*******************************************"
	@echo "***** Cleaning up previous deploys... *****"
	@echo "*******************************************"
	./cleanup.sh

build:
	@echo ""
	@echo "***********************************"
	@echo "***** Building environment... *****"
	@echo "***********************************"
	./build.sh

config:
	@echo ""
	@echo "**************************************"
	@echo "***** Configuring environment... *****"
	@echo "**************************************"
	./config.sh

validate:
	@echo ""
	@echo "*************************************************"
	@echo "***** Validation of deployed environment... *****"
	@echo "*************************************************"
	./validate.sh

doc:
	@echo ""
	@echo "**********************************************"
	@echo "***** Building Markdown doc from Org ... *****"
	@echo "**********************************************"
	pandoc -s --toc -f org -t commonmark -o README.markdown README.org
