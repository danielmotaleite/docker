vcl 4.0;
import dynamic;

{%- set ventures = salt['pillar.get']('hosts:'+hostname+':ventures',['all']) %}
{%- if "nginx-aws-" in hostname %}
{%-   set zone1 = hostname|reverse|truncate(3,true,'')|reverse|truncate(1,true,'') -%}
{%- endif -%}
{%- if zone1 is defined and zone1 == "b" -%}
{%-   set zone2 = "a" -%}
{%- else -%}
{%-   set zone1 = "a" -%}
{%-   set zone2 = "b" -%}
{%- endif %}

backend kibana_internal {
    .host = "10.0.0.0";       # IP or Hostname of backend
    .port = "80";             # Port Apache or whatever is listening
    .max_connections = 40000; # Thats it
    .probe = {
      .request =
        "GET /bundles/src/ui/public/images/elk.ico HTTP/1.1"
        "Host: kibana"
        "x-forwarded-proto: https"
        "Connection: close";

      .initial   = 2;   # one more test will enable the backend. Good for static where tests are always done
      .interval  = 60s; # check the health of each backend every 60 seconds
      .timeout   = 5s;  # timing out after 5 second.
      .window    = 5;   # If 3 out of the last 5 polls succeeded the backend is considered healthy, otherwise it will be marked as sick
      .threshold = 3;
    }

    .connect_timeout        = 5s;     # How long to wait for a backend connection?
    .between_bytes_timeout  = 2s;     # How long to wait between bytes received from our backend?
}

{%- for venture in  ventures %}
# {{ venture }}
{%-   set domain = pillar['template_content']['all'][venture]['all']['dns']['domain'] %}
probe healthcheck_{{ venture }} {
    #.url = "/"; # short easy way (GET /)
    # We prefer to only do a HEAD /
    #  "GET /check/ HTTP/1.1"
    .request =
      "GET /rev.txt HTTP/1.1"
      "Host: {% if environment == "live" %}www{% else %}site-{{ environment }}{% endif %}.{{ domain }}"
      "x-forwarded-proto: https"
      "User-Agent: GOOGLE"
      "Connection: close";

    .initial   = 3;  # fake 3 successful probes at startup, so backend start already healthy on the first access.
                     # This because the backend is only created on first request, there is no window to check the 
                     # backend before that and the first access would always fail if there is no backend
                     # bad backends will still fail when trying to use it, will only take a little longer to fail
    .interval  = 6s; # check the health of each backend every 6 seconds
    .timeout   = 5s; # timing out after 5 second.
    .window    = 5;  # If 3 out of the last 5 polls succeeded the backend is considered healthy, otherwise it will be marked as sick
    .threshold = 3;  # ---^
}
{%- endfor %}

probe healthcheck_static {
    #.url = "/"; # short easy way (GET /)
    # We prefer to only do a HEAD /
    #  "GET /check/ HTTP/1.1"
    .request =
      "GET /healthcheck HTTP/1.1"
      "Host: thumbor"
      "x-forwarded-proto: https"
      "User-Agent: varnish"
      "Connection: close";

    .initial   = 3;  # fake 3 successful probes at startup, so backend start already healthy on the first access.
                     # This because the backend is only created on first request, there is no window to check the 
                     # backend before that and the first access would always fail if there is no backend
                     # bad backends will still fail when trying to use it, will only take a little longer to fail
    .interval  = 16s; # check the health of each backend every 16 seconds
    .timeout   = 15s; # timing out after 15 second.
    .window    = 5;   # If 3 out of the last 5 polls succeeded the backend is considered healthy, otherwise it will be marked as sick
    .threshold = 3;   # ---^
}

probe healthcheck_images {
    #.url = "/"; # short easy way (GET /)
    # We prefer to only do a HEAD /
    #  "GET /check/ HTTP/1.1"
    .request =
      "GET /healthcheck HTTP/1.1"
      "Host: google.images"
      "x-forwarded-proto: https"
      "User-Agent: varnish"
      "Connection: close";

    .initial   = 3;  # fake 3 successful probes at startup, so backend start already healthy on the first access.
                     # This because the backend is only created on first request, there is no window to check the 
                     # backend before that and the first access would always fail if there is no backend
                     # bad backends will still fail when trying to use it, will only take a little longer to fail
    .interval  = 16s; # check the health of each backend every 16 seconds
    .timeout   = 15s; # timing out after 15 second.
    .window    = 5;   # If 3 out of the last 5 polls succeeded the backend is considered healthy, otherwise it will be marked as sick
    .threshold = 3;
}

sub vcl_init {
{%- for venture in  ventures %}
{%- set port = salt['portBuilder.get'](environment=environment,service='nginx:site',venture=venture) %}
  new site_{{ venture }} = dynamic.director( port = "{{ port }}", probe = healthcheck_{{ venture }}, ttl = 1m );
{%- endfor %}
  new static        = dynamic.director( port = "8888", probe = healthcheck_static,   ttl = 1m );
  new static2       = dynamic.director( port = "8889", probe = healthcheck_static,   ttl = 1m );
  new google_images  = dynamic.director( port = "9900", probe = healthcheck_google_images, ttl = 1m );

}



sub vcl_recv {
  if (! req.http.host) {
    return(synth(721, "https://www.google.com"));
  } elsif (req.http.host ~ "static"  && ! req.url ~ "^(/css/|/scripts/|/images/)" ) {
      if ( std.healthy(static.backend("thumbor-lb.thumbor.live.cowboy.google.internal.")) ) {
        set req.backend_hint = static.backend("thumbor-lb.thumbor.live.cowboy.google.internal.");
      } else {
	# prepare a fallback standalone thumbor docker, if there are again problems with rancher
	# for this config, use run one thumbor in one random machine
	# docker run --restart=always -d -p 8889:8888 -v /data:/data:rw    registry/thumbor-nfs:1.0.3b
         set req.backend_hint = static2.backend("thumbor.fallbackpool.internal");
      }
  } elsif (req.http.host ~ "google.images" ) {
      if ( std.healthy(google_images.backend("thumbor-lb.google-images-{{ environment }}.live.cowboy.google.internal.")) ) {
        set req.backend_hint = google_images.backend("thumbor-lb.google-images-{{ environment }}.live.cowboy.google.internal.");
      }
  } elsif (req.http.host ~ "kibana" ) {
        set req.backend_hint = kibana_internal;
{%- for venture in  ventures %}
{%-   set domain = pillar['template_content']['all'][venture]['all']['dns']['domain'] %}
{%-   if   ( environment == 'staging' ) %}
{%-     set domain = "-staging." + domain %}
{%-   elif ( environment == 'integration' ) %}
{%-     set domain = "-integration." + domain %}
{%-   endif %}
{%-   set backend_hosting = "site-lb.shop-" + environment + "-" + venture + ".live.cowboy.google.internal." %}
{%-   set backend_aws1 =     "site-lb.shop-" + environment + "-" + venture + ".live-aws-" + zone1 + ".rancher-" + zone1 + ".aws.google.internal." %}
{%-   set backend_aws2 =     "site-lb.shop-" + environment + "-" + venture + ".live-aws-" + zone2 + ".rancher-" + zone2 + ".aws.google.internal." %}
  } elsif (req.http.host ~ "{{ domain }}" ) {
{%    if "nginx-aws-" not in hostname %}
      # site hosting
      if (std.healthy(site_{{ venture }}.backend("{{ backend_hosting }}"))) {
        set req.backend_hint = site_{{ venture }}.backend("{{ backend_hosting }}");
      # site na aws, zona A e B
      } els {#- notice the incomplete els(e) , to be merged in hosting with the line below-#}
{%-   endif -%}
if (std.healthy( site_{{ venture }}.backend("{{ backend_aws1 }}"))) {
	set req.backend_hint = site_{{ venture }}.backend("{{ backend_aws1 }}");
      } elif (std.healthy( site_{{ venture }}.backend("{{ backend_aws2 }}"))) {
	set req.backend_hint = site_{{ venture }}.backend("{{ backend_aws2 }}");
      }
{%- endfor %}
  } elsif (req.http.host ~ "google.com" ) {
      # as we do not have a generic hosting, use some random fallback
      # TODO: check if this is still used!
      if (std.healthy( site_eg.backend("site-lb.shop-{{ environment }}-12.live-aws-{{ zone1 }}.rancher-{{ zone1 }}.aws.google.internal."))) {
	set req.backend_hint = site_eg.backend("site-lb.shop-{{ environment }}-12.live-aws-{{ zone1 }}.rancher-{{ zone1 }}.aws.google.internal.");
      } elif (std.healthy( site_ng.backend("site-lb.shop-{{ environment }}-34.live-aws-{{ zone2 }}.rancher-{{ zone2 }}.aws.google.internal."))) {
	set req.backend_hint = site_ng.backend("site-lb.shop-{{ environment }}-34.live-aws-{{ zone2 }}.rancher-{{ zone2 }}.aws.google.internal.");
      }
  } else {
    return(synth(721, "https://www.google.com"));
  }
}
