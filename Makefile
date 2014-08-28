subtitlex:
	MIX_ENV=prod mix do deps.get, deps.compile, cure.make, escript.build
