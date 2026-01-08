import Foundation

/// Common Chinese phrases found on signs
enum CommonPhrases {
    static let entries: [String: PhraseInfo] = [
        "出口": PhraseInfo(pinyin: "chū kǒu", meaning: "exit"),
        "入口": PhraseInfo(pinyin: "rù kǒu", meaning: "entrance"),
        "禁止": PhraseInfo(pinyin: "jìn zhǐ", meaning: "prohibited/forbidden"),
        "小心": PhraseInfo(pinyin: "xiǎo xīn", meaning: "be careful/caution"),
        "注意": PhraseInfo(pinyin: "zhù yì", meaning: "attention/notice"),
        "安全": PhraseInfo(pinyin: "ān quán", meaning: "safety/safe"),
        "危险": PhraseInfo(pinyin: "wēi xiǎn", meaning: "danger/dangerous"),
        "免费": PhraseInfo(pinyin: "miǎn fèi", meaning: "free (no charge)"),
        "收费": PhraseInfo(pinyin: "shōu fèi", meaning: "fee/charge"),
        "欢迎": PhraseInfo(pinyin: "huān yíng", meaning: "welcome"),
        "欢迎光临": PhraseInfo(pinyin: "huān yíng guāng lín", meaning: "welcome (to our establishment)"),
        "谢谢": PhraseInfo(pinyin: "xiè xiè", meaning: "thank you"),
        "对不起": PhraseInfo(pinyin: "duì bù qǐ", meaning: "sorry/excuse me"),
        "请进": PhraseInfo(pinyin: "qǐng jìn", meaning: "please enter"),
        "请勿": PhraseInfo(pinyin: "qǐng wù", meaning: "please do not"),
        "禁止吸烟": PhraseInfo(pinyin: "jìn zhǐ xī yān", meaning: "no smoking"),
        "禁止入内": PhraseInfo(pinyin: "jìn zhǐ rù nèi", meaning: "no entry"),
        "禁止拍照": PhraseInfo(pinyin: "jìn zhǐ pāi zhào", meaning: "no photography"),
        "停车场": PhraseInfo(pinyin: "tíng chē chǎng", meaning: "parking lot"),
        "火车站": PhraseInfo(pinyin: "huǒ chē zhàn", meaning: "train station"),
        "地铁站": PhraseInfo(pinyin: "dì tiě zhàn", meaning: "subway station"),
        "公交车": PhraseInfo(pinyin: "gōng jiāo chē", meaning: "public bus"),
        "飞机场": PhraseInfo(pinyin: "fēi jī chǎng", meaning: "airport"),
        "机场": PhraseInfo(pinyin: "jī chǎng", meaning: "airport"),
        "医院": PhraseInfo(pinyin: "yī yuàn", meaning: "hospital"),
        "银行": PhraseInfo(pinyin: "yín háng", meaning: "bank"),
        "超市": PhraseInfo(pinyin: "chāo shì", meaning: "supermarket"),
        "商店": PhraseInfo(pinyin: "shāng diàn", meaning: "shop/store"),
        "餐厅": PhraseInfo(pinyin: "cān tīng", meaning: "restaurant"),
        "饭店": PhraseInfo(pinyin: "fàn diàn", meaning: "restaurant/hotel"),
        "酒店": PhraseInfo(pinyin: "jiǔ diàn", meaning: "hotel"),
        "宾馆": PhraseInfo(pinyin: "bīn guǎn", meaning: "hotel/guesthouse"),
        "图书馆": PhraseInfo(pinyin: "tú shū guǎn", meaning: "library"),
        "公园": PhraseInfo(pinyin: "gōng yuán", meaning: "park"),
        "厕所": PhraseInfo(pinyin: "cè suǒ", meaning: "toilet/restroom"),
        "卫生间": PhraseInfo(pinyin: "wèi shēng jiān", meaning: "bathroom/restroom"),
        "洗手间": PhraseInfo(pinyin: "xǐ shǒu jiān", meaning: "restroom"),
        "男厕": PhraseInfo(pinyin: "nán cè", meaning: "men's room"),
        "女厕": PhraseInfo(pinyin: "nǚ cè", meaning: "women's room"),
        "电梯": PhraseInfo(pinyin: "diàn tī", meaning: "elevator"),
        "楼梯": PhraseInfo(pinyin: "lóu tī", meaning: "stairs"),
        "营业中": PhraseInfo(pinyin: "yíng yè zhōng", meaning: "open (for business)"),
        "休息中": PhraseInfo(pinyin: "xiū xī zhōng", meaning: "closed (taking a break)"),
        "售票处": PhraseInfo(pinyin: "shòu piào chù", meaning: "ticket office"),
        "服务台": PhraseInfo(pinyin: "fú wù tái", meaning: "service desk"),
        "问询处": PhraseInfo(pinyin: "wèn xún chù", meaning: "information desk"),
        "行李": PhraseInfo(pinyin: "xíng lǐ", meaning: "luggage"),
        "护照": PhraseInfo(pinyin: "hù zhào", meaning: "passport"),
        "签证": PhraseInfo(pinyin: "qiān zhèng", meaning: "visa"),
        "海关": PhraseInfo(pinyin: "hǎi guān", meaning: "customs"),
        "免税店": PhraseInfo(pinyin: "miǎn shuì diàn", meaning: "duty-free shop"),
        "外币兑换": PhraseInfo(pinyin: "wài bì duì huàn", meaning: "foreign currency exchange"),
    ]

    /// Find all known phrases within the given text
    static func findPhrases(in text: String) -> [(phrase: String, info: PhraseInfo)] {
        var found: [(phrase: String, info: PhraseInfo)] = []

        // Sort by length (longest first) to match longer phrases first
        let sortedPhrases = entries.keys.sorted { $0.count > $1.count }

        for phrase in sortedPhrases {
            if text.contains(phrase), let info = entries[phrase] {
                found.append((phrase, info))
            }
        }

        return found
    }

    /// Look up a specific phrase
    static func lookup(_ phrase: String) -> PhraseInfo? {
        entries[phrase]
    }
}
