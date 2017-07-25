function submitHashtags(url) {
  $.ajax({url: url,
    method: 'POST',
    data: {
      hashtags: $('tbody > tr.info').map(function() {return this.children[0].innerText;}).get()
    },
    success: function(result) {
      alert(result);
    },
    error: function(xhr, textStatus, errorThrown) {
      alert(errorThrown);
    }
  });
};
