// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import CoreWLAN
import Foundation

/// Returns the local IPv4 address, preferring wired (non-WiFi) interfaces.
func getLocalIPAddress() -> String? {
    let wifiInterface = CWWiFiClient.shared().interface()?.interfaceName

    var candidates: [(address: String, interface: String)] = []
    var ifaddr: UnsafeMutablePointer<ifaddrs>?
    guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else { return nil }
    defer { freeifaddrs(ifaddr) }

    for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
        let flags = Int32(ptr.pointee.ifa_flags)
        let addr = ptr.pointee.ifa_addr.pointee
        let name = String(cString: ptr.pointee.ifa_name)

        guard (flags & (IFF_UP | IFF_RUNNING)) != 0,
              (flags & IFF_LOOPBACK) == 0,
              addr.sa_family == UInt8(AF_INET) else { continue }

        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
        if getnameinfo(ptr.pointee.ifa_addr, socklen_t(addr.sa_len),
                       &hostname, socklen_t(hostname.count),
                       nil, 0, NI_NUMERICHOST) == 0 {
            candidates.append((String(cString: hostname), name))
        }
    }

    // Prefer wired (non-WiFi) interfaces for lower latency
    if let wired = candidates.first(where: { $0.interface != wifiInterface }) {
        return wired.address
    }
    return candidates.first?.address
}
