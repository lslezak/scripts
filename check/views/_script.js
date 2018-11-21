window.onload = function() {
  document.getElementById('show_all').addEventListener('change', (event) => {
    style = event.target.checked ? "none" : "table-row";
    document.querySelectorAll('.success_row').forEach(e => e.style.display = style);
  });
};
