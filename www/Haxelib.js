/*jslint white: false, onevar: true, browser: true, evil: true, undef: true, eqeqeq: true, regexp: true, newcap: true, immed: true */
/*global $  window TrimPath*/

var Haxelib = (function() {

    var filter = "All";

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

    function setFilter(f) {
        filter = f;
    }

    function getFilter() {
        return filter;
    }

    function inFilter(tags) {
        if (filter !== "All"){
            return $.grep(tags,function(el) {
                              return el.tag === filter;
                          }).length > 0;
        }
        return true;
    }

    function renderPackages(){
         $.getJSON(url("projects"),function(d) {
            var r = TrimPath.processDOMTemplate('tmpl-prj-list',{
                        projects:d.PAYLOAD,
                        safe:safe,
                        inFilter:inFilter,
                        filter:getFilter
            });
            $("#prj-list").html(r);
            $('.project-header').toggle(
                function() { $('.details',$(this).next()).css({display:'inline'}) ;},
                function() { $('.details',$(this).next()).css({display:'none'}); });

            $(".details").css({display:"none"});
        });
    }

    function renderTags(nTags,tmpl,dst){
        $.getJSON(url("toptags")+"&ntags="+nTags,function(td) {
           $(dst).html(TrimPath.processDOMTemplate(tmpl,td.PAYLOAD));
           $("a",dst).click(function(){
               var t = $(this).attr("id").split("-")[1] ;
               $("#filter-scope").html(t);
               setFilter(t);
               renderPackages();
           });
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
                renderTags(5,"tmpl-tags","#tag-space");
                renderPackages();
            break;
            case "docs":

            break;
            }
        });
    });

}());
