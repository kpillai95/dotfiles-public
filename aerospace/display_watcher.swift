import Foundation
import CoreGraphics

func outerTopValue() -> Int {
    var count: UInt32 = 0
    var displays = [CGDirectDisplayID](repeating: 0, count: 8)
    CGGetActiveDisplayList(8, &displays, &count)
    // Built-in display active = lid is open = use 3px (notch reserves the rest)
    // No built-in = clamshell = use 40px (full bar height needed as gap)
    let hasBuiltIn = (0..<Int(count)).contains { CGDisplayIsBuiltin(displays[$0]) != 0 }
    return hasBuiltIn ? 3 : 40
}

func runUpdateScript(outerTop: Int) {
    let script = NSHomeDirectory() + "/.config/aerospace/update_gaps.sh"
    let task = Process()
    task.launchPath = "/bin/bash"
    task.arguments = [script, String(outerTop)]
    task.environment = ["PATH": "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"]
    try? task.run()
    task.waitUntilExit()
}

var pendingWork: DispatchWorkItem?

func scheduleUpdate() {
    pendingWork?.cancel()
    let work = DispatchWorkItem {
        runUpdateScript(outerTop: outerTopValue())
    }
    pendingWork = work
    DispatchQueue.global().asyncAfter(deadline: .now() + 1.5, execute: work)
}

CGDisplayRegisterReconfigurationCallback({ _, flags, _ in
    // addFlag/removeFlag = physical plug/unplug
    // enabledFlag/disabledFlag = lid open/close (built-in display enabled or disabled)
    let relevant: CGDisplayChangeSummaryFlags = [.addFlag, .removeFlag, .enabledFlag, .disabledFlag]
    if !flags.intersection(relevant).isEmpty {
        scheduleUpdate()
    }
}, nil)

DispatchQueue.global().async {
    runUpdateScript(outerTop: outerTopValue())
}

RunLoop.main.run()
