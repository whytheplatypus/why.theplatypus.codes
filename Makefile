themes:
	mkdir themes
	git clone --recurse-submodules https://github.com/whytheplatypus/hugo-monotreme themes/monotreme

public: themes
	hugo -t monotreme --config config.toml -c .

serve:
	hugo serve -t monotreme --config config.toml - --contentDir .

clean:
	rm -r public
	rm -r resources
	rm -rf themes

.PHONY: clean serve
