docker pull sebp/elk
docker run -p 5601:5601 -p 9200:9200 -p 5044:5044 -it --name elk sebp/elk

# https://elk-docker.readthedocs.io
# https://hub.docker.com/r/sebp/elk/

# INITIALIZE KIBANA WITH DUMMY LOG
# (do this part with regular powershell, not ISE... which freezes)
# docker ps
# docker exec -it <container-name> /bin/bash
# /opt/logstash/bin/logstash --path.data /tmp/logstash/data \
#    -e 'input { stdin { } } output { elasticsearch { hosts => ["localhost"] } }'
# this is a dummy entry
# ^C

# ElasticSearch
# http://localhost:9200/_search?pretty
# config: /opt/elasticsearch/config/elasticsearch.yml
# -v /path/to/your-elasticsearch.yml:/opt/elasticsearch/config/elasticsearch.yml \

# Kibana
# http://localhost:5601
# config: /opt/kibana/config/kibana.yml
# -v /path/to/your-kibana.yml:/opt/kibana/config/kibana.yml \


# Logstash
# config: /opt/logstash/config/logstash.yml
# config: /etc/logstash/conf.d/02-beats-input.conf  
# config: /etc/logstash/conf.d/10-syslog.conf  
# config: /etc/logstash/conf.d/11-nginx.conf  
# config: /etc/logstash/conf.d/30-output.conf
# -v /path/to/your-logstash.yml:/opt/logstash/config/logstash.yml \
# -v /path/to/your-02-beats-input.conf:/etc/logstash/conf.d/02-beats-input.conf  
# -v /path/to/your-10-syslog.conf:/etc/logstash/conf.d/10-syslog.conf  
# -v /path/to/your-11-nginx.conf:/etc/logstash/conf.d/11-nginx.conf  
# -v /path/to/your-30-output.conf:/etc/logstash/conf.d/30-output.conf

# LOG DIRECTORY
# -v /path/to/your/logdir:/var/lib/elasticsearch

# INSTALL NGINX TO REVERSE-PROXY KIBANA
# docker exec -it <container-name> /bin/bash
# https://documentation.wazuh.com/2.0/installation-guide/optional-configurations/kibana_ssl.html#nginx-ssl-proxy-for-kibana-debian-based-distributions