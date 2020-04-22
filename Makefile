SOURCEFILE=index.bs
OUTPUTFILE=index.html
PREPROCESSOR=bikeshed
REMOTE_PREPROCESSOR_URL=https://api.csswg.org/bikeshed/

all: $(OUTPUTFILE)

$(OUTPUTFILE): $(SOURCEFILE)
ifneq (,$(REMOTE))
	curl $(REMOTE_PREPROCESSOR_URL) -F file=@$(SOURCEFILE) > "$@"
else
	$(PREPROCESSOR) -f spec "$<" "$@"
endif
