$(document).ready(function(){$("#dialog_content").dialog({resizable:false,autoOpen:false,height:400,width:700,maxWidth:700,modal:true,title:"Additional Details"});$(".details").bind("click",function(){var a=$(this);$.ajax({type:"GET",url:a.attr("data-url"),cache:false,success:function(c,b,d){$("#dialog_content").html(c).dialog("open")},error:function(c,b,d){alert("failure")}})});$(".search").fancyQueries()});