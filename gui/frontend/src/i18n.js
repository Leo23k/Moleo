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
  [/^(.+) is open\. Close it first: clearing the cache of a running app can break it until it restarts\.$/, '$1 đang mở. Hãy đóng trước: xoá cache khi app đang chạy có thể làm nó lỗi cho tới khi mở lại.'],
  [/^Left alone because they are open: (.+)$/, 'Bỏ qua vì đang mở: $1'],
  [/^⚠ Open apps are skipped: (.+)$/, '⚠ App đang mở sẽ được bỏ qua: $1'],
  [/^Done\. Freed about (.+)\.$/, 'Xong. Đã giải phóng khoảng $1.'],
  [/^(\d+) files · (.+)$/, '$1 file · $2'],
  [/^(\d+) groups · (.+) in extra copies$/, '$1 nhóm · $2 ở các bản thừa'],
  [/^Move (\d+) files to the Recycle Bin\?$/, 'Chuyển $1 file vào Thùng rác?'],
  [/^Moved (\d+) files to the Recycle Bin\.$/, 'Đã chuyển $1 file vào Thùng rác.'],
  [/^(.+) of extra copies\. One copy of each file is kept\.$/, '$1 bản thừa. Mỗi file luôn giữ lại một bản.'],
  [/^Empty the Recycle Bin afterwards to get the space back\.$/, 'Hãy dọn Thùng rác sau đó để lấy lại dung lượng.'],
  [/^Looking for large files… (.+) files checked$/, 'Đang tìm file lớn… đã kiểm tra $1 file'],
  [/^Comparing files… (.+) files checked$/, 'Đang so sánh file… đã kiểm tra $1 file'],
  [/^(.+) moved to (.+)\.$/, '$1 đã chuyển tới $2.'],
  [/^(.+) is back on the system drive\.$/, '$1 đã về lại ổ hệ thống.'],
  [/^(.+) · (.+) free$/, '$1 · trống $2'],
  [/^⚠ (.+?): (.+)$/, (m, name, text) => `⚠ ${name}: ${VI[text] || text}`],
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
  [/^(\d+) items in the Recycle Bin · newest first\. Restored items go back where they were; if a file with that name exists, the restored one gets a new name\.$/,
    '$1 mục trong Thùng rác · mới nhất trước. Mục khôi phục về đúng chỗ cũ; nếu đã có file trùng tên, file khôi phục sẽ được đặt tên mới.'],
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


// Warnings (⚠).
Object.assign(VI, {'Updates that are not installed yet will download again.': 'Bản cập nhật chưa cài sẽ phải tải lại.', 'Only needed if you want to report or debug a crash.': 'Chỉ cần khi bạn muốn báo lỗi hoặc gỡ lỗi crash.', "Large download: every project's dependencies must download again.": 'Dung lượng tải lớn: thư viện của mọi project sẽ phải tải lại.', 'Environments may need packages to download again.': 'Môi trường có thể phải tải lại các gói.', 'Modules download again on the next build.': 'Module sẽ tải lại ở lần build sau.', 'Crates download again on the next build.': 'Crate sẽ tải lại ở lần build sau.', 'Packages download again on the next restore.': 'Gói sẽ tải lại ở lần restore sau.', 'Browser tests will not run until browsers are installed again.': 'Test trình duyệt sẽ không chạy cho tới khi cài lại trình duyệt.', 'Tests will not run until the browser downloads again.': 'Test sẽ không chạy cho tới khi tải lại trình duyệt.', 'Unity packages download again when you open a project.': 'Package Unity sẽ tải lại khi mở project.', 'Deleted permanently. This cannot be undone.': 'Xoá vĩnh viễn. Không thể hoàn tác.', 'Old chat images and videos must download again; expired ones are gone.': 'Ảnh và video chat cũ phải tải lại; cái nào đã hết hạn sẽ mất luôn.', 'Used by Windows. Change it in system settings instead of deleting it.': 'Windows đang dùng. Hãy chỉnh trong cài đặt hệ thống thay vì xoá.', 'Windows restore points. Manage them in System Protection.': 'Điểm khôi phục của Windows. Quản lý trong System Protection.', 'The Recycle Bin. Empty it from the Clean tab.': 'Thùng rác. Hãy dọn ở tab Dọn dẹp.', 'Part of Windows. Deleting files here can stop Windows from starting.': 'Thuộc Windows. Xoá file ở đây có thể khiến Windows không khởi động được.', 'Installed apps. Remove them from the Apps tab so they uninstall cleanly.': 'Ứng dụng đã cài. Hãy gỡ ở tab Ứng dụng để gỡ sạch.', 'Shared app data and settings. Apps may stop working.': 'Dữ liệu và cài đặt dùng chung của app. App có thể ngừng hoạt động.', 'App settings and data. Use the Clean tab for caches.': 'Cài đặt và dữ liệu app. Hãy dùng tab Dọn dẹp để xoá cache.', 'Your personal files. Check before removing.': 'File cá nhân của bạn. Hãy kiểm tra trước khi xoá.', 'Version history of a project. Removing it loses all commits.': 'Lịch sử phiên bản của project. Xoá sẽ mất toàn bộ commit.', 'Shared runtime: other apps may stop working without it.': 'Runtime dùng chung: app khác có thể ngừng chạy nếu thiếu nó.', 'Driver or hardware software: a device may stop working.': 'Driver hoặc phần mềm phần cứng: thiết bị có thể ngừng hoạt động.', 'Security or anti-cheat software: games or protection may stop working.': 'Phần mềm bảo mật hoặc chống gian lận: game hoặc bảo vệ có thể ngừng hoạt động.', 'Part of Windows or its tools: Windows may reinstall or need it.': 'Thuộc Windows hoặc công cụ của nó: Windows có thể cần hoặc cài lại.'});

// Free up tab.
Object.assign(VI, {"Open": "Đang mở", "Updates install silently through winget. An app that is open may be closed by its installer: save your work first.": "Cập nhật được cài ngầm qua winget. App đang mở có thể bị trình cài đặt đóng lại: hãy lưu công việc trước.", "this folder is synced by OneDrive: move it from OneDrive settings instead": "thư mục này đang được OneDrive đồng bộ: hãy chuyển trong cài đặt OneDrive", "Used by the graphics driver for every app. Games and video may stutter or draw wrongly until it rebuilds; clear it right before a restart.": "Driver đồ hoạ dùng cho mọi app. Game và video có thể giật hoặc hiển thị sai cho tới khi tạo lại; nên xoá ngay trước khi khởi động lại máy.", "Already on another drive": "Đã ở ổ khác", "Free up": "Giải phóng", "Quick free-up": "Giải phóng nhanh", "Large files": "File lớn", "Move to another drive": "Chuyển sang ổ khác", "Duplicates": "File trùng lặp", "Measuring what can be freed…": "Đang đo dung lượng có thể giải phóng…", "Working…": "Đang chạy…", "Nothing to free": "Không có gì để dọn", "The biggest wins on the system drive, each fixed with one click by a built-in Windows tool.": "Những khoản lớn nhất trên ổ hệ thống, mỗi khoản xử lý bằng một cú bấm qua công cụ có sẵn của Windows.", "Measured:": "Đã đo:", "· these need administrator": "· cần quyền Admin", "Hibernation file": "File ngủ đông", "Previous Windows installation": "Bản Windows cũ", "Older restore points": "Điểm khôi phục cũ", "Windows component store (WinSxS)": "Kho thành phần Windows (WinSxS)", "WSL and Docker virtual disks": "Ổ ảo WSL và Docker", "Compress Windows files (Compact OS)": "Nén file Windows (Compact OS)", "Turns off hibernation and deletes hiberfil.sys. Sleep still works; Fast Startup is turned off.": "Tắt ngủ đông và xoá hiberfil.sys. Sleep vẫn dùng được; Fast Startup bị tắt.", "You can turn it back on with: powercfg /hibernate on": "Bật lại bằng lệnh: powercfg /hibernate on", "Windows.old and leftover upgrade files.": "Windows.old và file sót lại sau khi nâng cấp.", "After this you cannot go back to the previous Windows version.": "Sau đó không thể quay về bản Windows trước.", "Deletes every restore point on the system drive except the newest one.": "Xoá mọi điểm khôi phục trên ổ hệ thống, chỉ giữ bản mới nhất.", "You cannot roll Windows back to the deleted points.": "Không thể khôi phục Windows về các điểm đã xoá.", "needs administrator to measure": "cần quyền Admin để đo", "usually 1–5 GB": "thường 1–5 GB", "usually 2–4 GB": "thường 2–4 GB", "frees the empty space inside": "giải phóng phần trống bên trong", "Removes replaced versions of Windows components with DISM. Takes several minutes.": "Xoá các phiên bản thành phần Windows đã bị thay thế bằng DISM. Mất vài phút.", "Virtual disks grow but never shrink. This shuts down WSL and compacts them.": "Ổ ảo chỉ phình ra mà không tự co lại. Thao tác này tắt WSL và thu gọn chúng.", "WSL and Docker are stopped while compacting.": "WSL và Docker sẽ bị dừng trong lúc thu gọn.", "Compresses Windows system files. Slightly more CPU use when they load. Takes several minutes.": "Nén file hệ thống Windows. Tốn thêm chút CPU khi tải. Mất vài phút.", "Run Moleo as administrator first.": "Hãy chạy Moleo với quyền Admin trước.", "Drive": "Ổ", "Folder…": "Thư mục…", "At least": "Tối thiểu", "Find large files": "Tìm file lớn", "No files that large.": "Không có file nào lớn như vậy.", "Finds the biggest files: old installers, disk images, videos and archives.": "Tìm các file lớn nhất: bộ cài cũ, file ảnh đĩa, video và file nén.", "Removed files go to the Recycle Bin.": "File bị xoá sẽ vào Thùng rác.", "Looking for large files…": "Đang tìm file lớn…", "Comparing files…": "Đang so sánh file…", "disk image": "ảnh đĩa", "installer": "bộ cài", "archive": "file nén", "video": "video", "temporary": "file tạm", "Move to": "Chuyển tới", "Add a folder…": "Thêm thư mục…", "Move": "Chuyển", "Move back": "Chuyển về", "Moving…": "Đang chuyển…", "Moved": "Đã chuyển", "Move folder?": "Chuyển thư mục?", "Move back?": "Chuyển về?", "Measuring folders…": "Đang đo thư mục…", "There is no other drive to move folders to.": "Không có ổ khác để chuyển thư mục tới.", "Personal folders move like Properties › Location; others leave a link behind so apps keep working.": "Thư mục cá nhân được chuyển như Properties › Location; thư mục khác để lại liên kết ở chỗ cũ để app vẫn chạy.", "Personal folders": "Thư mục cá nhân", "Developer caches": "Cache lập trình", "AI models": "Model AI", "Virtual machines": "Máy ảo", "Your folders": "Thư mục của bạn", "Close Android Studio first.": "Hãy đóng Android Studio trước.", "Close Unity first.": "Hãy đóng Unity trước.", "Quit Ollama first.": "Hãy tắt Ollama trước.", "Quit LM Studio first.": "Hãy tắt LM Studio trước.", "Quit Docker Desktop first.": "Hãy tắt Docker Desktop trước.", "Find duplicates": "Tìm file trùng", "Your user folder (without AppData)": "Thư mục người dùng (trừ AppData)", "No duplicates found.": "Không có file trùng.", "Finds files with exactly the same content (checked by SHA-256), 1 MB or larger.": "Tìm file có nội dung giống hệt nhau (kiểm bằng SHA-256), từ 1 MB trở lên.", "The oldest copy in each group is kept by default.": "Mặc định giữ lại bản cũ nhất trong mỗi nhóm.", "⚠ At least one copy in each group is kept.": "⚠ Mỗi nhóm luôn giữ lại ít nhất một bản."});

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
