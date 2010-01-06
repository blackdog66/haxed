/*jslint white: false, onevar: true, browser: true, evil: true, undef: true, eqeqeq: true, regexp: true, newcap: true, immed: true */
/*global $  window TrimPath*/



var Haxelib = (function() {

    function url(u) {
        return "repo.php?method="+u;
    }

    function safe(p) {
        return p.split(".").join(",");
    }

    function renderServerInfo() {
        $.getJSON(url("serverInfo"),function(si) {
            var r = TrimPath.processDOMTemplate('tmpl-server-info',si.PAYLOAD);
            $("#intro-area").html(r);
        });
    }

    function renderPackages(){
         $.getJSON(url("projects"),function(d) {
            var r = TrimPath.processDOMTemplate('tmpl-prj-list',{
                        projects:d.PAYLOAD,
                        safe:safe
            });
            $("#prj-list").html(r);
            $('.project-header').toggle(
                function() { $('.details',$(this).next()).css({display:'inline'}) ;},
                function() { $('.details',$(this).next()).css({display:'none'}); });

            $(".details").css({display:"none"});
        });
    }

    $().ready(function() {
        $('#tab-container').tabs();
        $('#tab-container').bind('tabsshow', function(event, ui) {
	        var selected = $(ui.tab).text().toLowerCase();
            switch(selected) {
            case "home":
                renderServerInfo();
            break;
            case "packages":
                renderPackages();
            break;
            case "docs":

            break;
            }
        });
    });

}());
