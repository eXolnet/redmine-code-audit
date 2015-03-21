var AuditHelper = {
	table: function(path) {
		var target_path = $.trim(path),
			table = null;

		$('.filecontent').each(function() {
			var $this = $(this),
				path = $.trim($this.find('.filename').text());

			if (path == target_path) {
				table = $this;
			}
		});

		return table;
	},

	row: function(path, line_number) {
		var $table = typeof path == 'string' ?  AuditHelper.table(path) : path,
			$row = null;

		$table
			.find('.line-num:nth-child(3)')
			.each(function() {
				if ($(this).text() == line_number) {
					$row = $(this).closest('tr');
				}
			});

		return $row;
	},

	path: function(table) {
		return $.trim(table.find('.filename').text());
	},

	change_id: function(path) {
		if (typeof path != 'string') {
			path = AuditHelper.path(path);
		}

		change_id = null;

		$('.list-audit-changes tbody tr').each(function() {
			if ($(this).children('td:nth-child(4)').text() == path) {
				change_id = $(this).attr('data-change-id');
			}
		});

		return change_id;
	}
};

$(document).ready(function() {
	var nums = $('.line-num:nth-child(3)').filter(function() {
		return ! isNaN(parseFloat($(this).text()));
	});


	var comment_line_begin,
		comment_line_end,
		overlay,
		comment_index = 0;

	nums
		.each(function() {
			$(this).css('cursor', 'pointer');
		})
		.mousedown(function(e) {
			var $this = $(this),
				line = $this.next(),
				offset = line.offset();

			e.preventDefault();

			overlay = $('<div class="audit-comment-overlay" />');

			comment_line_begin = line;
			comment_line_end   = line;

			// Add the comment overlay
			overlay
				.css(offset)
				.css({
					width: line.outerWidth(),
					height: line.outerHeight()
				})
				.appendTo('body');

			// Overlay manipulation
			$this.closest('table')
				.find('.line-num')
				.filter(function() {
					return ! isNaN(parseFloat($(this).text()));
				})
				.mouseenter(function() {
					line2 = $(this).next(),
					offset2 = line2.offset();

					if (offset.top < offset2.top) {
						overlay
							.css(offset)
							.css({
								width: line.outerWidth(),
								height: offset2.top - offset.top + line2.outerHeight()
							});

						comment_line_begin = line;
						comment_line_end   = line2;
					} else {
						overlay
							.css(offset2)
							.css({
								width: line.outerWidth(),
								height: offset.top - offset2.top + line.outerHeight()
							});

						comment_line_begin = line2;
						comment_line_end   = line;
					}
				});
		})
		.mouseup(function() {
			$('.line-num').unbind('mouseenter');

			var row = comment_line_end.closest('tr');

			// Add the comment box
			var tr = $('<tr><th class="line-num" /><td class="line-comment" /><th class="line-num" /><td class="line-comment" /></tr>');

			tr.find('td:nth-child(4)')
				.append('<textarea rows="4"></textarea><p class="buttons"><input type="button" class="cancel" value="Cancel"> <input type="button" class="done" value="Done"></p>');

			var textarea = tr.find('textarea');

			var wikiToolbar = new jsToolBar(textarea.get(0));
			wikiToolbar.draw();

			tr.find('.cancel').click(function() {
				overlay.remove();
				tr.remove();
			});

			tr.find('.done').click(function() {
				var td = tr.find('td:nth-child(4)'),
					comment = textarea.val();

				overlay.remove();
				td.empty();

				// On ne permet pas l'ajout de commentaires vides
				if (comment == "") {
					return;
				}

				var line_begin = comment_line_begin.prev().text(),
					line_end   = comment_line_end.prev().text(),
					change_id  = AuditHelper.change_id(row.closest('table'));

				td.append('<div class="inline-comment inline-comment-draft" data-line-begin="' + line_begin + '" data-line-end="' + line_end + '">' +
						'<div class="inline-comment-header">' +
							'<span class="inline-comment-title">' + $('#comment_user_name').val() + ' (Draft)</span>' +
							'<span class="inline-comment-line">Line ' + line_begin + (line_begin != line_end ? '-'+line_end : '') + '</span>' +
						'</div>' +
						comment +
					'</div>');

				td.append('<input type="hidden" name="inline_comment[' + comment_index + '][line_begin]" value="' + line_begin + '" />');
				td.append('<input type="hidden" name="inline_comment[' + comment_index + '][line_end]" value="' + line_end + '" />');
				td.append('<input type="hidden" name="inline_comment[' + comment_index + '][change_id]" value="' + change_id + '" />');
				td.append('<input type="hidden" name="inline_comment[' + comment_index + '][content]" value="' + comment + '" />');

				comment_index += 1;
			});

			row.after(tr);

			textarea.focus();
		});



	$('.audit-change').click(function() {
		var $table = AuditHelper.table($(this).closest('td').next().text())
		$(document.body).animate({scrollTop: ($table.offset().top - 10) }, 500,'easeInOutCubic');

		return false;
	});

	var hover_overlay;

	$(document).on('mouseover', '.inline-comment', function() {
		var $this = $(this),
			$table = $this.closest('table'),
			$row_begin = AuditHelper.row($table, $this.attr('data-line-begin')),
			$row_end = AuditHelper.row($table, $this.attr('data-line-end')),
			$line_begin = $row_begin.find('td:nth-child(4)'),
			$line_end= $row_end.find('td:nth-child(4)');

		hover_overlay = $('<div class="audit-comment-overlay" />');

		hover_overlay
			.css($line_begin.offset())
			.css({
				width: $line_begin.outerWidth(),
				height: $line_end.offset().top - $line_begin.offset().top + $line_end.outerHeight()
			})
			.appendTo('body');
	});

	$(document).on('mouseout', '.inline-comment', function() {
		if (hover_overlay) {
			hover_overlay.remove();
			hover_overlay = null;
		}
	});


	// Création des inline comments déjà créés
	$('.inline-summary-content').each(function() {
		var $this = $(this),
			path = $this.attr('data-path'),
			audit_comment = $this.parents('.audit_comment'),
			line_begin = $this.attr('data-line-begin'),
			line_end = $this.attr('data-line-end') != "" ? $this.attr('data-line-end') : line_begin;

		var $row = AuditHelper.row(path, line_end);

		var tr = $('<tr><th class="line-num" /><td class="line-comment" /><th class="line-num" /><td class="line-comment" /></tr>'),
			td = tr.find('td:nth-child(4)');

		td.append('<div class="inline-comment" data-line-begin="' + line_begin + '" data-line-end="' + line_end + '">' +
						'<div class="inline-comment-header">' +
							'<span class="inline-comment-title">' + audit_comment.find('.title').html() + '</span>' +
							'<span class="inline-comment-line">Line ' + line_begin + (line_begin != line_end ? '-'+line_end : '') + '</span>' +
						'</div>' +
						$this.html() +
					'</div>');

		$row.after(tr);
	});


	$('.inline-line-number').click(function() {
		var $this = $(this),
			path = $this.attr('data-path'),
			line = $this.attr('data-line');

		var $row = AuditHelper.row(path, line);
		$(document.body).animate({scrollTop: ($row.offset().top - 10) }, 500,'easeInOutCubic');

		return false;
	});
});
