public extension Templates.Mocks {

    static func sitemap() -> String {
        """
        <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
            {{#empty(urls)}}
            {{/empty(urls)}}
            {{^empty(urls)}}
            <url>
            {{#urls}}
                <loc>{{location}}</loc>
                <lastmod>{{lastModification}}</lastmod>
            {{/urls}}
            </url>
            {{/empty(urls)}}
        </urlset>
        """
    }
}
