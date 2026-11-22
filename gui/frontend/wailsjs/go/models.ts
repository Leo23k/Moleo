export namespace main {
	
	export class AnalyzeItem {
	    name: string;
	    path: string;
	    size: number;
	    files: number;
	    isDir: boolean;
	    other: boolean;
	
	    static createFrom(source: any = {}) {
	        return new AnalyzeItem(source);
	    }
	
	    constructor(source: any = {}) {
	        if ('string' === typeof source) source = JSON.parse(source);
	        this.name = source["name"];
	        this.path = source["path"];
	        this.size = source["size"];
	        this.files = source["files"];
	        this.isDir = source["isDir"];
	        this.other = source["other"];
	    }
	}
	export class AnalyzeLevel {
	    path: string;
	    size: number;
	    files: number;
	    items: AnalyzeItem[];
	    root: string;
	
	    static createFrom(source: any = {}) {
	        return new AnalyzeLevel(source);
	    }
	
	    constructor(source: any = {}) {
	        if ('string' === typeof source) source = JSON.parse(source);
	        this.path = source["path"];
	        this.size = source["size"];
	        this.files = source["files"];
	        this.items = this.convertValues(source["items"], AnalyzeItem);
	        this.root = source["root"];
	    }
	
		convertValues(a: any, classs: any, asMap: boolean = false): any {
		    if (!a) {
		        return a;
		    }
		    if (a.slice && a.map) {
		        return (a as any[]).map(elem => this.convertValues(elem, classs));
		    } else if ("object" === typeof a) {
		        if (asMap) {
		            for (const key of Object.keys(a)) {
		                a[key] = new classs(a[key]);
		            }
		            return a;
		        }
		        return new classs(a);
		    }
		    return a;
		}
	}
	export class AppRecord {
	    Id: string;
	    Name: string;
	    Publisher: string;
	    Version: string;
	    SizeKB: number;
	    SizeHuman: string;
	    SizeChecked: boolean;
	    Source: string;
	
	    static createFrom(source: any = {}) {
	        return new AppRecord(source);
	    }
	
	    constructor(source: any = {}) {
	        if ('string' === typeof source) source = JSON.parse(source);
	        this.Id = source["Id"];
	        this.Name = source["Name"];
	        this.Publisher = source["Publisher"];
	        this.Version = source["Version"];
	        this.SizeKB = source["SizeKB"];
	        this.SizeHuman = source["SizeHuman"];
	        this.SizeChecked = source["SizeChecked"];
	        this.Source = source["Source"];
	    }
	}
	export class AppResult {
	    Id: string;
	    Name: string;
	    State: string;
	    Details: string;
	
	    static createFrom(source: any = {}) {
	        return new AppResult(source);
	    }
	
	    constructor(source: any = {}) {
	        if ('string' === typeof source) source = JSON.parse(source);
	        this.Id = source["Id"];
	        this.Name = source["Name"];
	        this.State = source["State"];
	        this.Details = source["Details"];
	    }
	}
	export class BinEntry {
	    id: string;
	    name: string;
	    original: string;
	    // Go type: time
	    deleted: any;
	    size: number;
	    isDir: boolean;
	
	    static createFrom(source: any = {}) {
	        return new BinEntry(source);
	    }
	
	    constructor(source: any = {}) {
	        if ('string' === typeof source) source = JSON.parse(source);
	        this.id = source["id"];
	        this.name = source["name"];
	        this.original = source["original"];
	        this.deleted = this.convertValues(source["deleted"], null);
	        this.size = source["size"];
	        this.isDir = source["isDir"];
	    }
	
		convertValues(a: any, classs: any, asMap: boolean = false): any {
		    if (!a) {
		        return a;
		    }
		    if (a.slice && a.map) {
		        return (a as any[]).map(elem => this.convertValues(elem, classs));
		    } else if ("object" === typeof a) {
		        if (asMap) {
		            for (const key of Object.keys(a)) {
		                a[key] = new classs(a[key]);
		            }
		            return a;
		        }
		        return new classs(a);
		    }
		    return a;
		}
	}
	export class CleanEntry {
	    id: string;
	    category: string;
	    name: string;
	    path: string;
	    bytes: number;
	    files: number;
	
	    static createFrom(source: any = {}) {
	        return new CleanEntry(source);
	    }
	
	    constructor(source: any = {}) {
	        if ('string' === typeof source) source = JSON.parse(source);
	        this.id = source["id"];
	        this.category = source["category"];
	        this.name = source["name"];
	        this.path = source["path"];
	        this.bytes = source["bytes"];
	        this.files = source["files"];
	    }
	}
	export class CleanResult {
	    removedBytes: number;
	    removedFiles: number;
	    skipped: number;
	    errors: string[];
	
	    static createFrom(source: any = {}) {
	        return new CleanResult(source);
	    }
	
	    constructor(source: any = {}) {
	        if ('string' === typeof source) source = JSON.parse(source);
	        this.removedBytes = source["removedBytes"];
	        this.removedFiles = source["removedFiles"];
	        this.skipped = source["skipped"];
	        this.errors = source["errors"];
	    }
	}
	export class category {
	    id: string;
	    name: string;
	    description: string;
	
	    static createFrom(source: any = {}) {
	        return new category(source);
	    }
	
	    constructor(source: any = {}) {
	        if ('string' === typeof source) source = JSON.parse(source);
	        this.id = source["id"];
	        this.name = source["name"];
	        this.description = source["description"];
	    }
	}
	export class CleanScan {
	    categories: category[];
	    entries: CleanEntry[];
	    locations: number;
	    bytes: number;
	
	    static createFrom(source: any = {}) {
	        return new CleanScan(source);
	    }
	
	    constructor(source: any = {}) {
	        if ('string' === typeof source) source = JSON.parse(source);
	        this.categories = this.convertValues(source["categories"], category);
	        this.entries = this.convertValues(source["entries"], CleanEntry);
	        this.locations = source["locations"];
	        this.bytes = source["bytes"];
	    }
	
		convertValues(a: any, classs: any, asMap: boolean = false): any {
		    if (!a) {
		        return a;
		    }
		    if (a.slice && a.map) {
		        return (a as any[]).map(elem => this.convertValues(elem, classs));
		    } else if ("object" === typeof a) {
		        if (asMap) {
		            for (const key of Object.keys(a)) {
		                a[key] = new classs(a[key]);
		            }
		            return a;
		        }
		        return new classs(a);
		    }
		    return a;
		}
	}
	export class DriveInfo {
	    path: string;
	    label: string;
	    total: number;
	    free: number;
	
	    static createFrom(source: any = {}) {
	        return new DriveInfo(source);
	    }
	
	    constructor(source: any = {}) {
	        if ('string' === typeof source) source = JSON.parse(source);
	        this.path = source["path"];
	        this.label = source["label"];
	        this.total = source["total"];
	        this.free = source["free"];
	    }
	}
	export class LostFile {
	    path: string;
	    name: string;
	    size: number;
	    // Go type: time
	    modified: any;
	    source: string;
	
	    static createFrom(source: any = {}) {
	        return new LostFile(source);
	    }
	
	    constructor(source: any = {}) {
	        if ('string' === typeof source) source = JSON.parse(source);
	        this.path = source["path"];
	        this.name = source["name"];
	        this.size = source["size"];
	        this.modified = this.convertValues(source["modified"], null);
	        this.source = source["source"];
	    }
	
		convertValues(a: any, classs: any, asMap: boolean = false): any {
		    if (!a) {
		        return a;
		    }
		    if (a.slice && a.map) {
		        return (a as any[]).map(elem => this.convertValues(elem, classs));
		    } else if ("object" === typeof a) {
		        if (asMap) {
		            for (const key of Object.keys(a)) {
		                a[key] = new classs(a[key]);
		            }
		            return a;
		        }
		        return new classs(a);
		    }
		    return a;
		}
	}
	export class OptimizeResult {
	    Id: string;
	    Name: string;
	    State: string;
	    Details: string;
	
	    static createFrom(source: any = {}) {
	        return new OptimizeResult(source);
	    }
	
	    constructor(source: any = {}) {
	        if ('string' === typeof source) source = JSON.parse(source);
	        this.Id = source["Id"];
	        this.Name = source["Name"];
	        this.State = source["State"];
	        this.Details = source["Details"];
	    }
	}
	export class OptimizeTask {
	    Id: string;
	    Name: string;
	    Kind: string;
	    Description: string;
	    needsAdmin: boolean;
	
	    static createFrom(source: any = {}) {
	        return new OptimizeTask(source);
	    }
	
	    constructor(source: any = {}) {
	        if ('string' === typeof source) source = JSON.parse(source);
	        this.Id = source["Id"];
	        this.Name = source["Name"];
	        this.Kind = source["Kind"];
	        this.Description = source["Description"];
	        this.needsAdmin = source["needsAdmin"];
	    }
	}
	export class ProcInfo {
	    name: string;
	    pid: number;
	    cpu: number;
	    mem: number;
	
	    static createFrom(source: any = {}) {
	        return new ProcInfo(source);
	    }
	
	    constructor(source: any = {}) {
	        if ('string' === typeof source) source = JSON.parse(source);
	        this.name = source["name"];
	        this.pid = source["pid"];
	        this.cpu = source["cpu"];
	        this.mem = source["mem"];
	    }
	}
	export class RestoreResult {
	    restored: string[];
	    errors: string[];
	
	    static createFrom(source: any = {}) {
	        return new RestoreResult(source);
	    }
	
	    constructor(source: any = {}) {
	        if ('string' === typeof source) source = JSON.parse(source);
	        this.restored = source["restored"];
	        this.errors = source["errors"];
	    }
	}
	export class ShadowVersion {
	    shadow: string;
	    created: string;
	    path: string;
	    size: number;
	    isDir: boolean;
	
	    static createFrom(source: any = {}) {
	        return new ShadowVersion(source);
	    }
	
	    constructor(source: any = {}) {
	        if ('string' === typeof source) source = JSON.parse(source);
	        this.shadow = source["shadow"];
	        this.created = source["created"];
	        this.path = source["path"];
	        this.size = source["size"];
	        this.isDir = source["isDir"];
	    }
	}
	export class StartupItem {
	    id: string;
	    name: string;
	    command: string;
	    location: string;
	    enabled: boolean;
	    needAdmin: boolean;
	
	    static createFrom(source: any = {}) {
	        return new StartupItem(source);
	    }
	
	    constructor(source: any = {}) {
	        if ('string' === typeof source) source = JSON.parse(source);
	        this.id = source["id"];
	        this.name = source["name"];
	        this.command = source["command"];
	        this.location = source["location"];
	        this.enabled = source["enabled"];
	        this.needAdmin = source["needAdmin"];
	    }
	}
	export class StatusSnapshot {
	    host: string;
	    os: string;
	    uptime: number;
	    cpuModel: string;
	    cores: number;
	    cpu: number;
	    perCore: number[];
	    memTotal: number;
	    memUsed: number;
	    swapTotal: number;
	    swapUsed: number;
	    drives: DriveInfo[];
	    netRx: number;
	    netTx: number;
	    topCpu: ProcInfo[];
	    topMem: ProcInfo[];
	    battery: number;
	    charging: boolean;
	
	    static createFrom(source: any = {}) {
	        return new StatusSnapshot(source);
	    }
	
	    constructor(source: any = {}) {
	        if ('string' === typeof source) source = JSON.parse(source);
	        this.host = source["host"];
	        this.os = source["os"];
	        this.uptime = source["uptime"];
	        this.cpuModel = source["cpuModel"];
	        this.cores = source["cores"];
	        this.cpu = source["cpu"];
	        this.perCore = source["perCore"];
	        this.memTotal = source["memTotal"];
	        this.memUsed = source["memUsed"];
	        this.swapTotal = source["swapTotal"];
	        this.swapUsed = source["swapUsed"];
	        this.drives = this.convertValues(source["drives"], DriveInfo);
	        this.netRx = source["netRx"];
	        this.netTx = source["netTx"];
	        this.topCpu = this.convertValues(source["topCpu"], ProcInfo);
	        this.topMem = this.convertValues(source["topMem"], ProcInfo);
	        this.battery = source["battery"];
	        this.charging = source["charging"];
	    }
	
		convertValues(a: any, classs: any, asMap: boolean = false): any {
		    if (!a) {
		        return a;
		    }
		    if (a.slice && a.map) {
		        return (a as any[]).map(elem => this.convertValues(elem, classs));
		    } else if ("object" === typeof a) {
		        if (asMap) {
		            for (const key of Object.keys(a)) {
		                a[key] = new classs(a[key]);
		            }
		            return a;
		        }
		        return new classs(a);
		    }
		    return a;
		}
	}
	export class UpdateItem {
	    name: string;
	    id: string;
	    version: string;
	    available: string;
	    source: string;
	
	    static createFrom(source: any = {}) {
	        return new UpdateItem(source);
	    }
	
	    constructor(source: any = {}) {
	        if ('string' === typeof source) source = JSON.parse(source);
	        this.name = source["name"];
	        this.id = source["id"];
	        this.version = source["version"];
	        this.available = source["available"];
	        this.source = source["source"];
	    }
	}

}

