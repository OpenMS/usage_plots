import pycurl
import sys
import re
from StringIO import StringIO

logfilename = sys.argv[1]
outputFilename = sys.argv[2]
stepsize = max(round(int(sys.argv[3])/50), 1)

logfile = open(logfilename, 'r')
outputFile = open(outputFilename, 'w')

pattern_xml_res = re.compile(".*\<CountryName\>(.*)\</CountryName\>.*\<RegionName\>(.*)\</RegionName\>.*\<City\>(.*)\</City\>.*\<ZipCode\>(.*)\</ZipCode\>.*\<Latitude\>(.*)\</Latitude\>.*\<Longitude\>(.*)\</Longitude\>", re.MULTILINE|re.DOTALL)

sys.stdout.write(''.join(['Processing file ', logfilename, '<']));
# the for loop assumes a tab seperated file of acces log information sorted by ip adress
old_ip = "";
olf_infos = "";
i = 1;
for line in logfile:
	ip = line.split("\t")[2];

	if (ip != old_ip):
		# get geolocation
		buffer = StringIO();
		c = pycurl.Curl();
		c.setopt(c.URL, 'freegeoip.net/xml/' + ip);
		c.setopt(c.WRITEDATA, buffer);
		c.perform();
		c.close();
		res = buffer.getvalue();

		m_res = re.match(pattern_xml_res, res);
		infos = "\t" + "\t".join([m_res.group(1), m_res.group(2), m_res.group(3), m_res.group(4), m_res.group(5), m_res.group(6)]) + "\n";

	# write output line
	outputFile.write(line.strip() + infos);

	# print progress
	if ((i % stepsize) == 0):
		sys.stdout.write('=');
		sys.stdout.flush();
	
	# update variables
	old_infos = infos;
	old_ip = ip;
	i = i + 1;

sys.stdout.write(''.join(['>\n', 'Output has been written to ', outputFilename]));
