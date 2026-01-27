// permalink:
// https://gist.githubusercontent.com/rfist/fb099ce9c5825740a8a439958abd4af8/raw/surfingkeys.txt
const {
    unmapAllExcept,
    mapkey,
    cmap,
    unmap,
    map,
    Hints,
    Clipboard,
    Front,
    aceVimMap,
    iunmap,
    imap
} = api;
settings.hintAlign = "left"
// always use omnibar
settings.tabsThreshold = 0;
// natural order tabs
settings.tabsMRUOrder = false;
// do not focus on input on page loaded
settings.stealFocusOnLoad = false;
// only keep tab navigation for calendar & email
unmapAllExcept(['E','R','T', 'B', 'F', 'm', '\'', 'p', 'b', 'f'], /calendar.google.com|mail.google.com|drive.google.com|youtube.com|music.youtube.com|trello.com/);
unmapAllExcept(['E','R','T', 'B', 'S', 'D', 'f', 'u', 'd', 'p'], /twitter.com/);
unmapAllExcept(['E','R','T', 'B', 'S', 'D'], /inoreader.com/);
unmapAllExcept(['E','R','T', 'B', 'S', 'D', 'j', 'k'], /rss./);
unmapAllExcept(['E','R','T', 'B', 'S', 'D', '<Ctrl-d>'], /meet.google.com/);
unmapAllExcept(['E','R','T', 'S', 'D', '<Ctrl-d>'], /calendar.notion.so/);
// now emoji is disabled by default, let's turn them back on
settings.enableEmojiInsertion = false;
// disable Emoji completion for web applications
iunmap(":", /telegram.org|slack.com|kibana|teams.microsoft.com|discord.com/);
// imap(',,', "<Esc>");        // press comma twice to leave current input box.

// setup Ace Vim
aceVimMap('jj', '<Esc>', 'insert');
aceVimMap('ZZ', ':wq', 'normal');

mapkey('ye', '#7Copy src URL of an image', function() {
    Hints.create('img[src]', function(element, event) {
        Clipboard.write(element.src);
    });
});
mapkey('yE', '#7Copy image to clipboard', function() {
    Hints.create('img[src]', async function(element, event) {
        try {
          const data = await fetch(element.src);
          const blob = await data.blob();
          await navigator.clipboard.write([
            new ClipboardItem({
              // The key is determined dynamically based on the blob's type.
              [blob.type]: blob
            })
          ]);
          console.log('Image copied.');
        } catch (err) {
          Front.showPopup(err.message);
          console.error(err.name, err.message);
        }
    });
});
mapkey('yM', 'Copy url as markdown link', function() {
      Clipboard.write(
    `[${document.title}](${window.location['href']})`,
  )
});
// jira
mapkey('<Alt-l>', 'Click Clear filters button', function() {
    // Find element by class and click it
    var btn = Array.from(document.querySelectorAll('span.css-178ag6o'))
        .find(el => el.innerText === 'Clear filters');
    if (btn) btn.click();
});

//// scroll
map('<Ctrl-d>', 'd'); // half scroll down
map('<Ctrl-u>', 'e'); // half scroll up
// easy enter fullscreen
map(',f', 'pf');
// edit and open current site url
map('O', ';U');
// open link in a non-active new tab
// map('F', 'C'); 
cmap('<Ctrl-n>', '<Tab>');
cmap('<Ctrl-p>', '<Shift-Tab>');

mapkey('gP', 'Go to the Pull requests tab.  ', function () {
    document.querySelectorAll('#pull-requests-tab')[0].click()
}, {
    domain: /github\.com/i
});
// google drive
mapkey('h', 'Go to the parent folder.  ', function () {
    const buttons = document.querySelectorAll('.o-Yc-o-T');
    buttons[buttons.length - 1].click();
}, {
    domain: /drive\.google/i
});


