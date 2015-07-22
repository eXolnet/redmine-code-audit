var AuditHelper = {
  side: {
    left: 0,
    right: 1,
  },
  // TODO: Load the changes as an object here instead of querying the DOM

  // Returns the DOM diff table (lines + text) for a specified path
  table: function(path) {
    return typeof path === 'string' ? $('.filecontent[data-path="' + path + '"]').first() : path;
  },

  // Returns the DOM row for a path and line number
  row: function(path, line_number) {
    var $table = AuditHelper.table(path)

    return $table.find('.line-num-right[data-line="' + line_number + '"]').first().parent();
  },

  line: function(path, line_number, side) {
    var $row = AuditHelper.row(path, line_number);
    var left = side === AuditHelper.side.left;

    return $row.find('.line-code.line-code-' + (left ? 'left' : 'right')).first();
  },

  // Returns the path associated to a diff table
  path: function(table) {
    return typeof table !== 'string' ? table.data('path') : table;
  },

  change_id: function(path) {
    var change_id = null;
    path = AuditHelper.path(path);

    var change = $('.list-audit-changes [data-path="' + path + '"]').first();

    if (change) {
      return change.data('change-id');
    }

    return change_id;
  }
};

jQuery.fn.previousElement = function(selector) {
  var currentElement = this;
  var elements = $(selector);
  if (elements.length === 0) {
    return;
  }

  var previousElement = null;
  elements.each(function(index, testedElement) {
    testedElement = $(testedElement);
    if (testedElement.is(currentElement)) {
      var index = index > 0 ? index - 1 : elements.length - 1;
      previousElement = elements[index];
      return false;
    }
  });
  return $(previousElement);
};

jQuery.fn.nextElement = function(selector) {
  var currentElement = this;
  var elements = $(selector);
  if (elements.length === 0) {
    return;
  }

  var nextElement = null;
  elements.each(function(index, testedElement) {
    testedElement = $(testedElement);
    if (testedElement.is(currentElement)) {
      var index = index + 1 < elements.length ? index + 1 : 0;
      nextElement = elements[index];
      return false;
    }
  });
  return $(nextElement);
};

$(document).ready(function() {
  var hover_overlay,
    comment_line_begin,
    comment_line_end,
    overlay,
    comment_index = 0,
    writingInlineComment = false;

  var inlineCommentsLinks = function() {
    return '<span class="inline-comment-links">' +
      '<a href="#" data-action="previous">Previous</a> · ' +
      '<a href="#" data-action="next">Next</a> · ' +
      '<a href="#" data-action="reply">Reply</a> · ' +
      '<a href="#" data-action="edit">Edit</a> · ' +
      '<a href="#" data-action="delete">Delete</a>' +
    '</span>';
  };

  var draftComment = function(line_begin, line_end, comment) {
    return '<div class="inline-comment inline-comment-draft" data-line-begin="' + line_begin + '" data-line-end="' + line_end + '">' +
      '<div class="inline-comment-header">' +
        '<span class="inline-comment-title">' + $('#comment_user_name').val() + ' (Draft)</span>' +
        inlineCommentsLinks() +
        '<span class="inline-comment-line">Line ' + line_begin + (line_begin != line_end ? '-'+line_end : '') + '</span>' +
      '</div>' +
      comment +
    '</div>';
  };

  var existingComment = function(line_begin, line_end, title, comment) {
    return '<div class="inline-comment" data-line-begin="' + line_begin + '" data-line-end="' + line_end + '">' +
      '<div class="inline-comment-header">' +
        '<span class="inline-comment-title">' + title + '</span>' +
         inlineCommentsLinks() +
        '<span class="inline-comment-line">Line ' + line_begin + (line_begin != line_end ? '-'+line_end : '') + '</span>' +
      '</div>' +
      comment +
    '</div>';
  };

  var showCommentEditor = function(path, line_begin, line_end) {
    if (writingInlineComment) {
      return;
    }
    writingInlineComment = true;
    var diff = AuditHelper.table(path);
    var row = AuditHelper.row(path, line_end);
    var change_id = AuditHelper.change_id(path);

    // Add the comment box
    var tr = $('<tr><th class="line-num line-num-left" /><td /><th class="line-num line-num-right" /><td class="line-comment" /></tr>');

    tr.find('.line-comment')
      .append('<textarea rows="4"></textarea><p class="buttons"><input type="button" class="cancel" value="Cancel"> <input type="button" class="done" value="Done"></p>');

    var textarea = tr.find('textarea');

    var wikiToolbar = new jsToolBar(textarea.get(0));
    wikiToolbar.draw();

    tr.find('.cancel').click(function() {
      destroyOverlay(overlay);
      tr.remove();
      writingInlineComment = false;
    });

    tr.find('.done').click(function() {
      var td = tr.find('.line-comment'),
        comment = textarea.val();

      destroyOverlay(overlay);
      td.empty();

      // Do not allow the creation of empty comments
      if (comment === '') {
        return;
      }

      td.append(draftComment(line_begin, line_end, comment));

      td.append('<input type="hidden" name="inline_comment[' + comment_index + '][line_begin]" value="' + line_begin + '" />');
      td.append('<input type="hidden" name="inline_comment[' + comment_index + '][line_end]" value="' + line_end + '" />');
      td.append('<input type="hidden" name="inline_comment[' + comment_index + '][change_id]" value="' + change_id + '" />');
      td.append('<input type="hidden" name="inline_comment[' + comment_index + '][content]" value="' + comment + '" />');

      comment_index += 1;
      writingInlineComment = false;
    });

    row.after(tr);

    textarea.focus();
  };

  var scrollTo = function(element) {
    $(document.body).animate({
      scrollTop: (element.offset().top - 10)
    }, 500, 'easeInOutCubic');
  };

  var createOverlay = function(line) {
    var overlay = $('<div class="audit-comment-overlay" />');

    // Add the comment overlay
    overlay
      .css(line.offset())
      .css({
        width: line.outerWidth(),
        height: line.outerHeight()
      })
      .appendTo('body');

      return overlay;
  };

  var updateOverlay = function(overlay, line_begin, line_end) {
    overlay
      .css(line_begin.offset())
      .css({
        width: line_end.outerWidth(),
        height: line_end.offset().top - line_begin.offset().top + line_end.outerHeight()
      });
  };

  var destroyOverlay = function(overlay) {
    if (overlay) {
      overlay.remove();
      overlay = null;
    }
  };

  var nums = $('.line-num-right[data-line]');

  nums
    .each(function() {
      $(this).css('cursor', 'pointer');
    })
    .mousedown(function(e) {
      if (writingInlineComment) {
        return;
      }

      var $this = $(this),
        line = $this.next();

      e.preventDefault();

      comment_line_begin = line;
      comment_line_end   = line;

      overlay = createOverlay(line);

      // Overlay manipulation
      var items = $this.closest('table')
        .find('.line-num.line-num-right[data-line]');


        items.mouseenter(function() {
          var line2 = $(this).next();

          if (line.prev().data('line') < line2.prev().data('line')) {
            comment_line_begin = line;
            comment_line_end   = line2;
          } else {
            comment_line_begin = line2;
            comment_line_end   = line;
          }

          updateOverlay(overlay, comment_line_begin, comment_line_end);
        });
    })
    .mouseup(function() {
      var $this = $(this);
      var path = $this.closest('table').data('path');
      $('.line-num').unbind('mouseenter');
      showCommentEditor(path, comment_line_begin.prev().data('line'), comment_line_end.prev().data('line'));
    });

  $('.audit-change').click(function() {
    var $table = AuditHelper.table($(this).closest('td').next().text())
    scrollTo($table);

    return false;
  });

  $(document).on('mouseover', '.inline-comment', function() {
    if (writingInlineComment) {
      return;
    }
    var $this = $(this),
      table = $this.closest('table'),
      line_begin = AuditHelper.line(table, $this.data('line-begin'), AuditHelper.side.right),
      line_end = AuditHelper.line(table, $this.data('line-end'), AuditHelper.side.right);

    destroyOverlay(hover_overlay);
    hover_overlay = createOverlay(line_begin);
    updateOverlay(hover_overlay, line_begin, line_end);
  });

  $(document).on('mouseout', '.inline-comment', function() {
    destroyOverlay(hover_overlay);
  });

  // Create existing inline comments
  $('.inline-summary-content').each(function() {
    var $this = $(this),
      path = $this.data('path'),
      audit_comment = $this.parents('.audit_comment'),
      line_begin = $this.data('line-begin'),
      line_end = $this.data('line-end') !== '' ? $this.data('line-end') : line_begin;

    var $row = AuditHelper.row(path, line_end);

    var tr = $('<tr><th class="line-num line-num-left" /><td /><th class="line-num line-num-right" /><td class="line-comment" /></tr>'),
      td = tr.find('.line-comment');

    td.append(existingComment(line_begin, line_end, audit_comment.find('.title').html(), $this.html()));

    $row.after(tr);
  });

  // Scrolls to the diff
  $('.inline-line-number').click(function() {
    var $this = $(this),
      path = $this.data('path'),
      line = $this.data('line');

    var $row = AuditHelper.row(path, line);
    scrollTo($row);

    return false;
  });

  $(document).on('click', '.inline-comment-links [data-action="previous"]', function(e) {
    e.preventDefault();
    var $this = $(this);
    var previousComment = $this.closest('.inline-comment').previousElement('.inline-comment');
    scrollTo(previousComment);
  });

  $(document).on('click', '.inline-comment-links [data-action="next"]', function(e) {
    e.preventDefault();
    var $this = $(this);
    var nextComment = $this.closest('.inline-comment').nextElement('.inline-comment');
    scrollTo(nextComment);
  });

  $(document).on('click', '.inline-comment-links [data-action="reply"]', function(e) {
    e.preventDefault();
    var $this = $(this);
    var targetComment = $this.closest('.inline-comment');
    var path = targetComment.closest('.filecontent').data('path');
    var line_begin = targetComment.data('line-begin');
    var line_end = targetComment.data('line-end');
    showCommentEditor(path, line_begin, line_end);
  });

  $(document).on('click', '.inline-comment-links [data-action="edit"]', function(e) {

  });

  $(document).on('click', '.inline-comment-links [data-action="delete"]', function(e) {

  });
});
