const search = document.querySelector('#course-search');
if (search) {
  const links = [...document.querySelectorAll('#lesson-list a')];
  search.addEventListener('input', () => {
    const query = search.value.trim().toLocaleLowerCase();
    for (const link of links) {
      link.hidden = !link.textContent.toLocaleLowerCase().includes(query);
    }
  });
}
