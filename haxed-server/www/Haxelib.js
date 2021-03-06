/*jslint white: false, onevar: true, browser: true, evil: true, undef: true, eqeqeq: true, regexp: true, newcap: true, immed: true */
/*global $  window TrimPath*/

var Haxelib = (function() {

    var
        filter = "None",
        filterFld = "",
        myModifiers = {
          toHTML: function(str) {
            return str.replace(/\\n/g,"<br/>");
          },
          toURL: function(str) {
              return '<a href="'+str+'" target="_new">'+str+'</a>';
          }
        };

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

    function setFilterFld(ff) {
       filterFld = ff;
    }

    function getFilterFld() {
       return filterFld;
    }

    function renderPackageList(d) {
        if (d.ERR === "ERR_PROJECTNOTFOUND") {
           $("#prj-list").html("None found");
           return;
        }

        var
        data = {
            projects:d.PAYLOAD,
            filter:getFilter,
            filterFld:function() {
                var fv = getFilterFld();
                return (fv === "") ? "" : fv + " contains ";
            },
            safe:safe
            },
        r;

        data._MODIFIERS = myModifiers;

        r = TrimPath.processDOMTemplate('tmpl-prj-list',data);

        $("#prj-list").html(r);
        $('.project-header').toggle(
            function() { $('.details',$(this).next()).css({display:'inline'}) ;},
            function() { $('.details',$(this).next()).css({display:'none'}); });

        $(".details").css({display:"none"});

        $("#nofilter").click(function() {
            setFilter("None");
            setFilterFld("");
            queryAll();
        });
    }

    function queryTags(){
         $.getJSON(url("search")+"&query="+getFilter()+"&-St=true",renderPackageList);
    }

    function queryNames() {
        $.getJSON(url("search")+"&query="+getFilter()+"&-Sf="+getFilterFld(),renderPackageList);
    }

    function queryAll() {
        $.getJSON(url("projects"),renderPackageList);
    }

    function renderTags(nTags,tmpl,dst){
        $.getJSON(url("toptags")+"&ntags="+nTags,function(td) {
           $(dst).html(TrimPath.processDOMTemplate(tmpl,td.PAYLOAD));
           $("a",dst).click(function(){
               var t = $(this).attr("id").split("-")[1] ;
               $("#filter-scope").html(t);
               setFilter(t);
               queryTags();
           });
        });
    }

    function setupSearch() {
		$("#btnQuery").click(function() {
           setFilter($("#txtQuery").val());
           setFilterFld($('#selFld').val());
           queryNames();
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
                queryAll();
                setupSearch();
            break;
            case "docs":

            break;
            }
        });
    });

}());
