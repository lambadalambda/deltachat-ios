import Testing
@testable import deltachat_ios

struct HtmlMessageTextExtractorTests {
    @Test func stripsUnsafeTagsAndPreservesReadableStructure() {
        let html = """
        <html><head><style>.x { color: red }</style></head><body>
          <p>Hello <b>World</b> &amp; friends</p>
          <script>alert('xss')</script>
          <p>Second line<br>with break</p>
        </body></html>
        """

        let text = HtmlMessageTextExtractor.extractText(from: html)
        #expect(text == "Hello World & friends\nSecond line\nwith break")
    }

    @Test func decodesEntitiesAndNormalizesWhitespace() {
        let html = "&lt;tag&gt; &#x1F680; &nbsp; &quot;quoted&quot;"
        let text = HtmlMessageTextExtractor.extractText(from: html)
        #expect(text == "<tag> 🚀 \"quoted\"")
    }
}
