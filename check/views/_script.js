
"use strict";

// load the same page into an iframe
function update_page()
{
  var iframe = document.createElement('iframe');
  iframe.style.display = "none";
  iframe.src = document.URL;
  document.body.appendChild(iframe);
}

function failure_ids(node)
{
  var ids = [];
  node.querySelectorAll("*[id^='failure_id:']").forEach( (item) => {
    ids.push(item.id)
  });
  return ids;
}

function new_items(old_array, new_array)
{
  var new_items = new_array.filter(function(item) {
    return old_array.indexOf(item) < 0;
  });

  return new_items;
}

function receiveMessage(event)
{
  var iframe = document.querySelectorAll("iframe")[0];
  // TODO: what if no iframe?

  if (iframe.contentWindow != event.source)
    return;

  console.log("Received message:", event.data);

  var current_ids = failure_ids(document);
  var loaded_ids = failure_ids(iframe.contentWindow.document.body);
  var new_ids = new_items(current_ids, loaded_ids);

  var new_pg = document.querySelectorAll("iframe")[0].contentWindow.document.getElementById("page");

  // remove the iframe and the old page
  document.body.removeChild(iframe);
  document.body.removeChild(document.getElementById("page"));

  // add the new content
  document.body.appendChild(new_pg);

  // TODO: register again the filter button handler

  // highlight the new failures
  new_ids.forEach( (id) => {
    document.getElementById(id).className += " highlight";
  });

  // TODO: report the new failures via HTML5 notifications
}

window.addEventListener("message", receiveMessage, false);

window.onload = function() {
  // handle changing the "Filter" check box value
  document.getElementById('show_all').addEventListener('change', (event) => {
    var style = event.target.checked ? "none" : "table-row";
    document.querySelectorAll('.success_row').forEach(e => e.style.display = style);
  });

  if (window != window.parent)
  {
    window.parent.postMessage("New document loaded", document.URL);
  }

  // check the new issues every 5 minutes
  window.setInterval(update_page, 5*60*1000);
};
