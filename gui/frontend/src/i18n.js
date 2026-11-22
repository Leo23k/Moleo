// UI language. English is the source text in the code; Vietnamese is
// applied to rendered text nodes and placeholder/title attributes, so
// pages don't need to know about languages. User data (app names, paths)
// never matches a whole-string rule, so it is left alone.

const KEY = 'moleo.lang';
export let lang = 'en';
try { lang = localStorage.getItem(KEY) === 'vi' ? 'vi' : 'en'; } catch { /* storage unavailable */ }

const VI = {
  // nav
  'Clean': 'Dọn dẹp', 'Apps': 'Ứng dụng', 'Optimize': 'Tối ưu', 'Analyze': 'Phân tích', 'Status': 'Trạng thái', 'Recover': 'Khôi phục',
  // common
  'Cancel': 'Huỷ', 'Back': 'Quay lại', 'Done': 'Xong', 'OK': 'OK', 'Search': 'Tìm kiếm', 'Refresh': 'Làm mới',
  'Close': 'Đóng', 'Scan again': 'Quét lại', 'Try again': 'Thử lại', 'Show in Explorer': 'Mở trong Explorer',
  'Run as administrator': 'Chạy với quyền Admin', 'Choose…': 'Chọn…', 'Scanning…': 'Đang quét…',
  // clean
  'Scan': 'Quét', 'Ready to clean': 'Sẵn sàng dọn dẹp', 'All': 'Tất cả', 'None': 'Bỏ chọn', 'Recommended': 'Đề xuất',
  'Cleaning…': 'Đang dọn…',
  'System Data': 'Dữ liệu hệ thống', 'App caches & logs': 'Cache & log ứng dụng', 'Developer Tools': 'Công cụ lập trình',
  'AI Tools': 'Công cụ AI', 'Communication': 'Liên lạc', 'Games': 'Trò chơi', 'Recycle Bin': 'Thùng rác',
  'Windows temporary files, crash dumps and graphics caches. Rebuilt automatically.': 'File tạm của Windows, crash dump và cache đồ hoạ. Tự tạo lại.',
  'App and browser caches, plus old logs.': 'Cache của ứng dụng và trình duyệt, cùng log cũ.',
  'Package manager and IDE caches. The first build afterwards is slower.': 'Cache trình quản lý gói và IDE. Lần build đầu sau đó sẽ chậm hơn.',
  'AI app and CLI caches. Conversations, projects, and local models are kept.': 'Cache của app và CLI AI. Hội thoại, project và model local được giữ lại.',
  'Chat app caches. Old chat images and videos must re-download.': 'Cache app chat. Ảnh và video chat cũ sẽ phải tải lại.',
  'Launcher web caches and game logs. Games and saves are kept.': 'Cache web của launcher và log game. Game và save được giữ lại.',
  'Empties selected Recycle Bin items permanently.': 'Xoá vĩnh viễn các mục đã chọn trong Thùng rác.',
  'Recycle Bin items are removed permanently.': 'Các mục trong Thùng rác sẽ bị xoá vĩnh viễn.',
  // apps
  'Uninstall': 'Gỡ cài đặt', 'Updates': 'Cập nhật', 'Startup': 'Khởi động', 'Name': 'Tên', 'App size': 'Dung lượng',
  'Clear selection': 'Bỏ chọn', 'Remove': 'Gỡ', 'Back to apps': 'Quay lại danh sách', 'Uninstall stopped': 'Đã dừng gỡ cài đặt',
  'Reading installed apps…': 'Đang đọc danh sách ứng dụng…', 'Checking for updates with winget…': 'Đang kiểm tra cập nhật qua winget…',
  'Update': 'Cập nhật', 'Updating…': 'Đang cập nhật…', 'Updated ✓': 'Đã cập nhật ✓', 'Failed': 'Lỗi',
  'Updates install silently through winget.': 'Cập nhật được cài ngầm qua winget.', 'winget (App Installer) is required.': 'Cần có winget (App Installer).',
  'Open backups': 'Mở bản sao lưu', 'All users': 'Mọi người dùng', 'Store app': 'App Store',
  'Each uninstaller runs (some show their own window). Leftover files go to the Recycle Bin, and registry entries are backed up first.':
    'Trình gỡ của từng app sẽ chạy (một số hiện cửa sổ riêng). File sót lại được đưa vào Thùng rác, registry được sao lưu trước.',
  // analyze
  'Choose a drive': 'Chọn ổ đĩa', 'Choose a folder': 'Chọn thư mục', 'Map your disk': 'Quét ổ đĩa',
  'Click a block to look inside.': 'Bấm vào một khối để xem bên trong.', 'A treemap shows what fills the disk.': 'Treemap cho thấy thứ gì chiếm ổ đĩa.',
  'Move to Recycle Bin': 'Chuyển vào Thùng rác', 'Select items to move them to the Recycle Bin': 'Chọn mục để chuyển vào Thùng rác',
  'Up one level': 'Lên một cấp', 'Local Disk': 'Ổ đĩa cục bộ', 'Starting…': 'Đang bắt đầu…', 'Could not remove': 'Không xoá được',
  'You can restore them from the Recycle Bin.': 'Bạn có thể khôi phục từ Thùng rác.',
  // optimize
  'Loading tasks…': 'Đang tải tác vụ…', 'Optimizing…': 'Đang tối ưu…', 'Optimize results': 'Kết quả tối ưu', 'Choose tasks': 'Chọn tác vụ',
  'check': 'kiểm tra', 'admin': 'admin',
  'Optimize system drive': 'Tối ưu ổ hệ thống', 'Clear DNS cache': 'Xoá DNS cache', 'Clear ARP cache': 'Xoá ARP cache',
  'Startup programs': 'Chương trình khởi động', 'Disk health': 'Sức khoẻ ổ đĩa', 'Windows Update': 'Windows Update', 'System image health': 'Tình trạng system image',
  'Run Windows default volume optimization on the system drive. Requires administrator privileges.': 'Chạy tối ưu ổ đĩa mặc định của Windows trên ổ hệ thống. Cần quyền Admin.',
  'Flush the Windows DNS resolver cache. Existing connections may resolve names again.': 'Xoá DNS cache của Windows. Các kết nối có thể phân giải tên lại.',
  'Clear the local ARP cache. Windows will repopulate it as needed. Requires administrator privileges.': 'Xoá ARP cache. Windows sẽ tự tạo lại khi cần. Cần quyền Admin.',
  'Count registered startup entries. This check does not disable anything.': 'Đếm các mục khởi động. Không tắt mục nào.',
  'Read physical disk health reported by Windows.': 'Đọc tình trạng ổ đĩa vật lý do Windows báo cáo.',
  'Check for available Windows updates. This does not install updates.': 'Kiểm tra bản cập nhật Windows. Không cài đặt gì.',
  'Read the Windows component store health verdict. Requires administrator privileges; this does not attempt repair.': 'Đọc tình trạng component store của Windows. Cần quyền Admin; không sửa chữa.',
  // status
  'Reading system status…': 'Đang đọc trạng thái hệ thống…', 'CPU': 'CPU', 'Memory': 'Bộ nhớ', 'Network': 'Mạng', 'Disks': 'Ổ đĩa',
  'Top CPU': 'Tốn CPU nhất', 'Top memory': 'Tốn RAM nhất',
  // recover
  'Lost recordings': 'Bản ghi bị mất', 'Previous versions': 'Phiên bản cũ', 'Deep scan': 'Quét sâu',
  'Reading the Recycle Bin…': 'Đang đọc Thùng rác…', 'Restore': 'Khôi phục', 'Save copies…': 'Lưu bản sao…', 'Save copy…': 'Lưu bản sao…',
  'Looking for unsaved recordings and captures…': 'Đang tìm bản ghi và ảnh chụp chưa lưu…',
  'The Recycle Bin is empty. For files deleted from it, use Deep scan.': 'Thùng rác trống. Với file đã xoá khỏi Thùng rác, hãy dùng Quét sâu.',
  'Nothing found. If the file was deleted, try Deep scan.': 'Không tìm thấy gì. Nếu file đã bị xoá, hãy thử Quét sâu.',
  'Find versions': 'Tìm phiên bản', 'Searching restore points…': 'Đang tìm trong điểm khôi phục…',
  'No older copies of this path were found.': 'Không tìm thấy bản cũ nào của đường dẫn này.',
  'Windows keeps older copies of files in restore points (shadow copies) when System Protection is on.':
    'Windows giữ bản cũ của file trong điểm khôi phục (shadow copy) khi bật System Protection.',
  'Enter the full path of a file or folder — it can be one you already deleted.': 'Nhập đường dẫn đầy đủ của file hoặc thư mục — kể cả cái đã xoá.',
  'Open Microsoft Store': 'Mở Microsoft Store', 'I installed it': 'Tôi đã cài xong',
  'Stop using the drive': 'Ngừng dùng ổ đĩa', 'Scan drive': 'Ổ cần quét', 'Find': 'Tìm', 'Mode': 'Chế độ', 'Save to (other drive)': 'Lưu vào (ổ khác)',
  'Regular — recently deleted (NTFS)': 'Thường — mới xoá gần đây (NTFS)', 'Extensive — older, formatted, FAT/exFAT': 'Kỹ — xoá lâu, đã format, FAT/exFAT',
  'Start deep scan': 'Bắt đầu quét sâu', 'Stop': 'Dừng', 'Start': 'Bắt đầu', 'Start deep scan?': 'Bắt đầu quét sâu?',
  'Output appears here.': 'Kết quả sẽ hiện ở đây.', 'Scanning… this can take a long time.': 'Đang quét… có thể mất nhiều thời gian.',
  'Choose a folder on another drive': 'Chọn thư mục ở ổ khác',
};

// Patterns for text with numbers or names inside. Order matters.
const VI_RULES = [
  [/^App size ↓$/, 'Dung lượng ↓'],
  [/^(\d+) selected$/, '$1 đã chọn'],
  [/^(\d+)\/(\d+) selected$/, '$1/$2 đã chọn'],
  [/^Clean · (.+)$/, 'Dọn · $1'],
  [/^Permanently clean · (.+)$/, 'Xoá vĩnh viễn · $1'],
  [/^Clean (.+)\?$/, 'Dọn $1?'],
  [/^(.+) cleanable · (\d+) items · (\d+) categories · (\d+) locations checked$/, '$1 có thể dọn · $2 mục · $3 nhóm · đã kiểm tra $4 vị trí'],
  [/^Checked (\d+) of (\d+) · (.+)$/, 'Đã kiểm tra $1/$2 · $3'],
  [/^(\d+) items will be deleted\. Files that are in use are skipped\.$/, '$1 mục sẽ bị xoá. File đang được dùng sẽ được bỏ qua.'],
  [/^Freed$/, 'Đã giải phóng'],
  [/^ · (\d+) files removed$/, ' · đã xoá $1 file'],
  [/^(\d+) files in use or protected were skipped$/, '$1 file đang dùng hoặc được bảo vệ đã được bỏ qua'],
  [/^Installed Apps · (\d+) apps · (.+)$/, 'Ứng dụng đã cài · $1 app · $2'],
  [/^(\d+) apps · (.+)$/, '$1 app · $2'],
  [/^Remove (\d+)$/, 'Gỡ $1'],
  [/^Remove (\d+) apps?\?$/, 'Gỡ $1 app?'],
  [/^Removing (\d+) apps?… follow any uninstaller windows that open\.$/, 'Đang gỡ $1 app… hãy làm theo cửa sổ gỡ cài đặt nếu có.'],
  [/^(\d+) updates available$/, 'Có $1 bản cập nhật'],
  [/^Update all (\d+)$/, 'Cập nhật tất cả $1'],
  [/^(\d+) startup items · (\d+) enabled$/, '$1 mục khởi động · $2 đang bật'],
  [/^Move (\d+) items? to the Recycle Bin\?$/, 'Chuyển $1 mục vào Thùng rác?'],
  [/^(\d+) selected · (.+)$/, '$1 đã chọn · $2'],
  [/^(.+) used of (.+) · (.+) free$/, 'Đã dùng $1 / $2 · trống $3'],
  [/^(.+) free$/, 'trống $1'],
  [/^(\d+) smaller files$/, '$1 file nhỏ hơn'],
  [/^(\d+) of (\d+) tasks$/, '$1/$2 tác vụ'],
  [/^ · some need administrator$/, ' · một số cần quyền Admin'],
  [/^(\d+) logical cores$/, '$1 nhân logic'],
  [/^(\d+) items in the Recycle Bin · newest first\.$/, '$1 mục trong Thùng rác · mới nhất trước.'],
  [/^Restore (\d+)$/, 'Khôi phục $1'],
  [/^(.+) · deleted (.+)$/, '$1 · xoá lúc $2'],
  [/^Restored (\d+) items?$/, 'Đã khôi phục $1 mục'],
  [/^Saved (\d+) items?$/, 'Đã lưu $1 mục'],
  [/^Could not list apps: (.+)$/, 'Không đọc được danh sách app: $1'],
  [/^Scan failed: (.+)$/, 'Quét thất bại: $1'],
  [/^Clean failed: (.+)$/, 'Dọn thất bại: $1'],
  [/^Finished\. Recovered files are in (.+)$/, 'Xong. File khôi phục nằm trong $1'],
  [/^(.+) needs administrator rights\.$/, '$1 cần quyền Admin.'],
  [/^(\d[\d,.]*) files · (.+)$/, '$1 file · $2'],
  [/^ · (\d[\d,.]*) files$/, ' · $1 file'],
  [/^(.+)% · (\d[\d,.]*) files$/, '$1% · $2 file'],
];

// Longer explanatory lines that sit next to markup.
Object.assign(VI, {
  '200+ cache locations, checked one by one.': 'Hơn 200 vị trí cache, kiểm tra từng chỗ một.',
  'Nothing is deleted until you choose.': 'Không xoá gì cho tới khi bạn chọn.',
  'Refresh DNS and network caches, optimize the drive, and check disk, update and system health.':
    'Làm mới cache DNS và mạng, tối ưu ổ đĩa, kiểm tra sức khoẻ ổ đĩa, cập nhật và hệ thống.',
  ' · a backup is saved before every change · ': ' · bản sao lưu được tạo trước mỗi thay đổi · ',
  'Restored items go back where they were; if a file with that name exists, the restored one gets a new name.':
    'Mục khôi phục về đúng chỗ cũ; nếu đã có file trùng tên, file khôi phục sẽ được đặt tên mới.',
  'Videos, audio and images left in app temp folders in the last 60 days —\n    for example a Snipping Tool recording cut off by a shutdown. Files are copied, never moved.\n    A cut-off recording may need a video repair tool to play.':
    'Video, âm thanh và ảnh còn sót trong thư mục tạm của app trong 60 ngày qua — ví dụ bản ghi Snipping Tool bị ngắt do tắt máy. File chỉ được sao chép, không di chuyển. Bản ghi bị ngắt có thể cần công cụ sửa video để phát.',
  'Deep scan finds files deleted from the Recycle Bin or long ago, using Microsoft\'s free ': 'Quét sâu tìm file đã xoá khỏi Thùng rác hoặc xoá từ lâu, bằng công cụ miễn phí của Microsoft: ',
  'Install it from the Microsoft Store, then come back.': 'Hãy cài từ Microsoft Store rồi quay lại.',
  ': new files can overwrite deleted ones.\n    On SSDs, Windows usually wipes deleted data within minutes (TRIM), so results there are limited; HDDs, USB sticks and SD cards recover best.':
    ': file mới có thể ghi đè lên file đã xoá. Trên SSD, Windows thường xoá hẳn dữ liệu trong vài phút (TRIM) nên khó cứu; ổ HDD, USB và thẻ nhớ cứu được tốt nhất.',
});

function tr(text) {
  const t = text.replace(/\s+/g, ' ');
  const trimmed = t.trim();
  if (!trimmed) return null;
  const exact = VI[trimmed] ?? VI[text] ?? VI[text.trim()];
  if (exact !== undefined) return t.replace(trimmed, exact);
  for (const [re, rep] of VI_RULES) {
    if (re.test(t)) return t.replace(re, rep);
    if (re.test(trimmed)) return t.replace(trimmed, trimmed.replace(re, rep));
  }
  return null;
}

const ORIG = new WeakMap();   // node -> original English text
function translateNode(n) {
  if (n.nodeType === 3) {
    const p = n.parentNode;
    if (!p || p.closest('.path, input, textarea, pre, .tname')) return;
    const en = ORIG.get(n) ?? n.nodeValue;
    const out = lang === 'vi' ? tr(en) : null;
    if (out !== null && out !== n.nodeValue) { ORIG.set(n, en); n.nodeValue = out; }
    else if (lang === 'en' && ORIG.has(n)) { n.nodeValue = ORIG.get(n); ORIG.delete(n); }
    return;
  }
  if (n.nodeType !== 1) return;
  for (const attr of ['placeholder', 'title']) {
    const v = n.getAttribute(attr);
    if (!v) continue;
    const key = 'data-en-' + attr;
    const en = n.getAttribute(key) ?? v;
    if (lang === 'vi') {
      const out = tr(en);
      if (out !== null) { n.setAttribute(key, en); n.setAttribute(attr, out); }
    } else if (n.hasAttribute(key)) { n.setAttribute(attr, en); n.removeAttribute(key); }
  }
  for (const c of n.childNodes) translateNode(c);
}

let observer = null;
export function startI18n(onChange) {
  const apply = () => translateNode(document.body);
  observer = new MutationObserver(muts => {
    if (lang !== 'vi') return;
    observer.disconnect();
    for (const m of muts) {
      if (m.type === 'characterData') translateNode(m.target);
      m.addedNodes.forEach(translateNode);
    }
    observer.observe(document.body, {childList: true, subtree: true, characterData: true});
  });
  observer.observe(document.body, {childList: true, subtree: true, characterData: true});
  document.documentElement.lang = lang;
  apply();
  const sw = document.getElementById('lang');
  const paint = () => sw.querySelectorAll('button').forEach(b => b.classList.toggle('on', b.dataset.lang === lang));
  sw.querySelectorAll('button').forEach(b => b.onclick = () => {
    if (b.dataset.lang === lang) return;
    lang = b.dataset.lang;
    try { localStorage.setItem(KEY, lang); } catch { /* ignore */ }
    document.documentElement.lang = lang;
    paint();
    apply();
    onChange && onChange();
  });
  paint();
}
