//
//  SwapInfo.swift
//  Portal
//
//  Created by farid on 4/24/23.
//

import Foundation

struct SwapInfo {
    let hash: String
    let secret: String
    let holderPubKey: String
    let seekerInvoice: String
    let seekerL1Address: String
    let timelock: Int32
    let amount: Int32
    let fee: Int32
}

extension SwapInfo {
    static var mocked: SwapInfo {
        let hash = "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
        let secret = "JNRMmjEDLAw6XiveTb7O1N86Xwt7qzmmzV82K1jsA78="
        let holderPubKey = "03d16e7689325feee0ae2530be4c19d0c255ff84359d0fa0795f1ebc63d841965c"
        let seekerInvoice = "lnbcrt500u1pjy9tw8dqqnp4qv6lgq5akth5qmk6a8wg56ak9pze7sn2lpn2utsx0mvu8q20zzns5pp5uwcvgs5clswpfxhm7nyfjmaeysn6us0yvjdexn9yjkv3k7zjhp2ssp553hx30waccaus9z2ueffpul6v7cslrxr75pl2ft7tpl085ts8twq9qyysgqcqpcxqyz5vqrzjqt28qzxnfyzwf9y7hp67qpeqh5klhk7ueacl8regy2ckjleqf43ajqqzwyqqqqgqqyqqqqlgqqqqqqgq9qep0zh4e5wp6da74yxc2qnwjt9f8tgq25da2phde4r9s3nua6ktpx2e5x6s5yv5t2yeqs598d57w5nlzwyrc6u732c4cnsnr3yv92u0gpe9y98w"
        let seekerL1Address = "bcrt1q8k0csahdjwhcpanc3uzxxju7p78a8sv5whp2wjs0kxg58sysqrrslzhrxn"
        let timelock: Int32 = 652
        let amount: Int32 = 50000
        let fee: Int32 = 1000
        
        return SwapInfo(
            hash: hash,
            secret: secret,
            holderPubKey: holderPubKey,
            seekerInvoice: seekerInvoice,
            seekerL1Address: seekerL1Address,
            timelock: timelock,
            amount: amount,
            fee: fee
        )
    }
}
