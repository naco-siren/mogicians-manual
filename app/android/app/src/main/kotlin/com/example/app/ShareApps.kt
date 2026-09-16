package com.example.app

/**
 * Phone-to-phone transfer apps worth pointing the user at when sharing the
 * installer. Every package listed here must also appear in the manifest's
 * <queries> block, or Android 11+ hides it from the package manager.
 * Labels are fallbacks; the installed app's own label is preferred.
 */
object ShareApps {
    data class Candidate(val packageName: String, val label: String)

    val candidates = listOf(
        // System-level 互传联盟 services shipped by Chinese ROMs.
        Candidate("com.miui.mishare.connectivity", "小米互传"),
        Candidate("com.coloros.oshare", "OPPO 互传"),
        Candidate("com.oplus.oshare", "OPPO 互传"),
        Candidate("com.vivo.easyshare", "vivo 互传"),
        Candidate("com.hihonor.android.instantshare", "荣耀分享"),
        Candidate("com.huawei.android.instantshare", "华为分享"),
        // Standalone apps.
        Candidate("com.xiaomi.midrop", "ShareMe"),
        Candidate("com.dewmobile.kuaiya", "快牙"),
        Candidate("com.dewmobile.kuaiya.play", "Zapya"),
        Candidate("com.lenovo.anyshare", "茄子快传"),
        Candidate("com.lenovo.anyshare.gps", "SHAREit"),
        Candidate("cn.xender", "闪传"),
        Candidate("moe.reimu.catshare", "CatShare"),
        Candidate("org.localsend.localsend_app", "LocalSend"),
        Candidate("com.google.android.apps.nbu.files", "Files"),
    )
}
