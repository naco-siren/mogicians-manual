package com.example.app

/**
 * Phone-to-phone transfer apps worth pointing the user at when sharing the
 * installer, in the order they should be offered:
 *
 * 1. the phone maker's own system-level share service,
 * 2. maker / platform apps that come from an app store,
 * 3. community open-source apps, most popular first,
 * 4. third-party closed-source apps that work but are bloated with ads.
 *
 * Every package listed here must also appear in the manifest's <queries>
 * block, or Android 11+ hides it from the package manager. Labels are ours,
 * not the app's (whose label follows the phone's locale): a China build gets
 * its Chinese name, an international build its English one.
 */
object ShareApps {
    enum class Tier { SYSTEM, STORE, OPEN_SOURCE, AD_SUPPORTED }

    data class Candidate(val packageName: String, val label: String, val tier: Tier)

    val candidates: List<Candidate> = listOf(
        // 1. System-level services (互传联盟 members and their peers). Package
        //    names verified against vendor stores / firmware lists, 2026-09.
        Candidate("com.miui.mishare.connectivity", "小米互传", Tier.SYSTEM),
        Candidate("com.coloros.oshare", "OPPO 互传", Tier.SYSTEM),
        Candidate("com.oneplus.oshare", "OnePlus Share", Tier.SYSTEM),
        Candidate("com.vivo.easyshare", "vivo 互传", Tier.SYSTEM),
        Candidate("com.hihonor.android.instantshare", "荣耀分享", Tier.SYSTEM),
        Candidate("com.huawei.android.instantshare", "华为分享", Tier.SYSTEM),
        Candidate("com.samsung.android.app.sharelive", "三星 Quick Share", Tier.SYSTEM),
        Candidate("com.samsung.android.aware.service", "三星 Quick Share", Tier.SYSTEM),
        // 2. Maker / platform apps from a store.
        Candidate("com.google.android.apps.nbu.files", "Files by Google", Tier.STORE),
        Candidate("com.xiaomi.midrop", "ShareMe", Tier.STORE),
        // 3. Open source, most popular first.
        Candidate("org.localsend.localsend_app", "LocalSend", Tier.OPEN_SOURCE),
        Candidate("moe.reimu.catshare", "CatShare", Tier.OPEN_SOURCE),
        // 4. Closed source with ads; China build first, then the Play build.
        Candidate("com.dewmobile.kuaiya", "快牙", Tier.AD_SUPPORTED),
        Candidate("com.dewmobile.kuaiya.play", "Zapya", Tier.AD_SUPPORTED),
        Candidate("com.lenovo.anyshare", "茄子快传", Tier.AD_SUPPORTED),
        Candidate("com.lenovo.anyshare.gps", "SHAREit", Tier.AD_SUPPORTED),
        Candidate("cn.xender", "Xender", Tier.AD_SUPPORTED),
    ).sortedBy { it.tier }
}
