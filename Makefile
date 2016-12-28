.PHONY: release

version ?= $(shell mix run --no-start -e 'IO.puts Mix.Project.config[:version]')
image   ?= jemc/promenade

release: $(foreach path, mix.exs mix.lock lib rel config priv, $(shell find $(path)))
	docker run --rm \
		-v ${PWD}/lib:/source/lib \
		-v ${PWD}/rel:/source/rel \
		-v ${PWD}/priv:/source/priv \
		-v ${PWD}/config:/source/config \
		-v ${PWD}/mix.exs:/source/mix.exs \
		-v ${PWD}/mix.lock:/source/mix.lock \
		-v ${PWD}/tarballs:/stage/tarballs \
		edib/edib-tool:1.4.0
	
	@# Reset terminal coloring, since edib-tool leaves it as bold green.
	@tput sgr0 || :
	
	cat ${PWD}/tarballs/promenade-$(version).tar.gz | \
		docker import \
			--change 'WORKDIR /app' \
			--change 'ENV PATH /app/bin:/bin' \
			--change 'CMD trap exit TERM; /app/bin/promenade foreground & wait' - \
			$(image):$(version)
	
	docker tag $(image):$(version) $(image)
