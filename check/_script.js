window.onload = function() {
  document.getElementById('show_all').addEventListener('change', (event) => {
    style = event.target.checked ? "none" : "block";
    document.querySelectorAll('.success_line').forEach(e => e.style.display = style);
  });
};
