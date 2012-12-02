use Xchat ':all';
use File::Slurp;

register('everest-sysinfo', time, "sysinfo script using output from everest", sub{ prnt "everest-sysinfo unloaded"; });

#everest doesn't output a standard csv file: there's the base sysinfo heading and there's the two-row header
#I'll have to slurp it and do something with those before eating it with a csv parser.
#maybe it'd be easier to just learn how to read the registry,
#or make the csv pretend to be json(or D::D output?) and eval it
#I could just eat every line with split but that feels like giving up, not to mention fragility

#in any event, the purpose of this was that wsys isn't very customizable, 
#particularly /meminfo looks like ass and (all but )?one valueset in /diskinfo is backwards