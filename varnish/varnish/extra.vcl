#
# VCL file for Varnish.
#
# Enables page cache for some component
# @author Samuel Nogueira <snogueira@jumia.com>

# Marker to tell the VCL compiler that this VCL has been adapted to the
# new 4.0 format.
vcl 4.0;

sub vcl_recv {

    # Set X-Language header, which will be needed to differentiate cache versions
    if (req.http.Cookie ~ "userLanguage=") {
        set req.http.X-Language = regsub(req.http.Cookie + ";", ".*userLanguage=([^;]+);.*", "\1");
    }
    # Set X-Scenario header, which will be needed to differentiate AB Testing cache versions
    if (req.http.Cookie ~ "search_term=" && req.url ~ "q=") {
		set req.http.X-Scenario = regsub(req.http.Cookie + ";", ".*search_term=([^;]+);.*", "\1");
    }
    if (req.http.Cookie ~ "ABTests=") {
        set req.http.X-ABTests = regsub(req.http.Cookie + ";", ".*ABTests=([^;]+);.*", "\1");
    }

    #Check for android/Ios because we have specific css for each one.
    set req.http.X-OS  = "";
    if (req.http.User-Agent ~ "(?i)Android") {
        set req.http.X-OS = "Android";
    }
    if (req.http.User-Agent ~ "(?i)iPhone") {
        set req.http.X-OS = "iPhone";
    }

    # No device cookie available, do our own device detect
    if (req.http.Cookie !~ "device=") {
        # Set the X-UA-Device header, which will be needed to differentiate cache versions
        call devicedetect;

        # Use device detection script, but replace some values for compatibility
        # with shop's own mobile detect ("pc" becomes "desktop", there is
        # no device "tablet", and detect Opera Mini as "mobileMini")

        set req.http.X-UA-Device = regsub(req.http.X-UA-Device, "\-.+", "");
        set req.http.X-UA-Device = regsub(req.http.X-UA-Device, "pc", "desktop");
        set req.http.X-UA-Device = regsub(req.http.X-UA-Device, "tablet", "desktop");
        if (req.http.User-Agent ~ "(?i)opera mini") {
            set req.http.X-UA-Device = "mobileMini";
        }

        if (req.http.User-Agent ~ "(?i)tizen") {
            set req.http.X-UA-Device = "mobile";
        }

        # Append fake device cookie (request to PHP will set the true cookie)
        if (!req.http.Cookie) {
            set req.http.Cookie = "device=" + req.http.X-UA-Device;
        } else {
            set req.http.Cookie = req.http.Cookie + ";device=" + req.http.X-UA-Device;
        }
        # We won't be needing this anymore
        unset req.http.X-UA-Device;
    }

    set req.http.X-Device = regsub(req.http.Cookie + ";", ".*device=([^;]+);.*", "\1");

    # Remove cookies from request so there's a chance of this getting cached
    set req.http.X-Cookie = req.http.Cookie;
    if (req.http.Cookie ~ "universalLogin=1") {
        return(pass);
    }

    unset req.http.Cookie;
}

sub vcl_backend_fetch {
    # Restore cookies to request
    set bereq.http.Cookie = bereq.http.X-Cookie;
    unset bereq.http.X-Cookie;

    # Add a Surrogate-Capability header to announce ESI support.
    set bereq.http.Surrogate-Capability = "key=ESI/1.0";
}

sub vcl_backend_response {
    # Enable ESI processing if backend announces it's usage
    if (beresp.http.Surrogate-Control ~ "ESI/1.0") {
        set beresp.do_esi = true;
    }

    # Add X-Device, X-OS, X-Language, X-ABTests and X-Scenario to Vary header
    set beresp.http.Vary = regsub(beresp.http.Vary + ", X-Device, X-Language, X-ABTests, X-Scenario, X-OS", "^, ", ""); # add and trim

    # Add header to log the varnish backend used
    set beresp.http.X-Backend = beresp.backend.name;
}

sub vcl_deliver {
    # Remove X-Device , X-OS, X-Language, X-ABTests and X-Scenario from Vary header
    if (resp.http.Vary == "X-Device, X-Language, X-Scenario, X-ABTests, X-OS") {
        unset resp.http.Vary;
    } else {
        set resp.http.Vary = regsub(resp.http.Vary, ", X-Device, X-Language, X-ABTests, X-Scenario, X-OS", "");
    }

    # If our response had an ESI tag in it, let's assume it has customer data
    # in it, and should not be cacheable for any proxy standing between us and
    # the final customer
    if (resp.http.Surrogate-Control ~ "ESI/1.0") {
        set resp.http.Cache-Control = "no-store, no-cache, must-revalidate, post-check=0, pre-check=0";
        set resp.http.Pragma = "no-cache";

        unset resp.http.Surrogate-Control;
        unset resp.http.Expires;
    }
}

