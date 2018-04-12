
var widgetTpl = document.getElementById("widget-tpl").innerHTML;
var widgetPullsTpl = document.getElementById("widget-pulls-tpl").innerHTML;
var pullsWidget = document.getElementById("widget-pulls");
var uatWidget = document.getElementById("widget-uat");

function tick() {
  var pulls = pegasus("https://api.github.com/repos/NHS-digital-website/hippo/pulls");
  pulls.then(
    handlePulls,
    // error handler (optional)
    function(data, xhr) {
      console.error(data, xhr.status)
    }
  );

  var uatChanges = pegasus("https://api.github.com/repos/NHS-digital-website/hippo/compare/prd...uat");
  uatChanges.then(
    handleUatChanges,
    // error handler (optional)
    function(data, xhr) {
      console.error(data, xhr.status)
    }
  );
}

function handlePulls(data, xhr) {
  var viewData = {
    name: "Github",
    count: data.length,
    of: data.length == 1 ? "pull request" : "pull requests",
    items: getPullRequestItems(data)
  };

  pullsWidget.innerHTML = Mustache.render(widgetPullsTpl, viewData);
}

function getPullRequestItems(data) {
  var items = [ ];

  data.forEach(function(pull) {
    items.push({
      title: pull.title,
      user_avatar: pull.user.avatar_url
    })
  });

  return items;
}

function handleUatChanges(data, xhr) {
  uatWidget.innerHTML = Mustache.render(widgetTpl, getChangesData(data, "Acceptance Environment"));
}

function getChangesData(data, name) {
  var items = [ ];
  data.commits.forEach(function(commit) {
    items.push({
      title: commit.commit.message.split('\n')[0],
      user_avatar: commit.author ? commit.author.avatar_url : "http://via.placeholder.com/48x48?text=unknown"
    });
  });
  return {
    name: name,
    count: data.total_commits,
    of: data.total_commits == 1 ? "change" : "changes",
    items: items
  };
}

tick();
