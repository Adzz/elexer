import Config

if config_env() == :debug do
  config(:elexer, with_trace?: true)
else
  config(:elexer, with_trace?: false)
end
