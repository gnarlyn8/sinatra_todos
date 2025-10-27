$(function () {
  $("form.delete").submit(function (event) {
    event.preventDefault();
    event.stopPropagation();

    const ok = confirm("Aryou sure? This cannot be undone");
    if (ok) {
      this.submit();
    }
  });
});
