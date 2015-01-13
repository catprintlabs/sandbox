jQuery(document).ready(function($) {
  console.log('adding an uploader!');
  var create_uploader = function () {$('#jq_form_here').uploader({
    user: "me@benhughes.name",
    multiple: true,
    create: function (f) {
      console.log('new uploader created: '+this.attr('id')+" "+f.status);
    },
    submit: function (f) {
      console.log('file upload submitted!');
      create_uploader();
    },
    progress: function (f) {
      console.log("progress is being made on "+f.progress.name+" - secure_token: "+f.progress.secure_token+" percent loaded: "+Math.round(f.progress.percent_complete*100));
    }
  });};
  create_uploader();
  $('#jq_form_here').uploader({
    user: "me@benhughes.name",
    http_link: window.location.host+"/catprintqrcode.png",
    submit: function (f) {
      console.log('http submitted!');
    },
    progress: function (f) {
      console.log('http progress on '+f.progress.name);
    }
  });
});