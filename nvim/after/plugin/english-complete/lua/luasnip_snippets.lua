print('loaded markdown snippets')

local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local d = ls.dynamic_node
local f = ls.function_node
local c = ls.choice_node
local rep = require("luasnip.extras").rep -- For repeating values

-- You can define helper functions if you find yourself reusing logic
local function get_current_date()
    return os.date("%Y-%m-%d") -- e.g., 2025-05-22
end

local function get_current_time()
    return os.date("%H:%M") -- e.g., 14:27
end

return {
    -- Basic heading
    s({
        trig = "h1",
        dscr = "Level 1 Heading",
    }, {
        t("# "),
        i(1, "Main Topic"),
        i(0),
    }),

    s({
        trig = "h2",
        dscr = "Level 2 Heading",
    }, {
        t("## "),
        i(1, "Subtopic"),
        i(0),
    }),

    -- Paragraph boilerplate
    s({
        trig = "para",
        dscr = "New paragraph",
    }, {
        i(1, "Start typing your paragraph here."),
        i(0),
    }),

    -- Blockquote
    s({
        trig = "bq",
        dscr = "Blockquote",
    }, {
        t("> "),
        i(1, "Quote text"),
        i(0),
    }),

    -- Unordered list item
    s({
        trig = "li",
        dscr = "List item",
    }, {
        t("- "),
        i(1, "List item content"),
        i(0),
    }),

    -- Ordered list item
    s({
        trig = "ol",
        dscr = "Ordered list item",
    }, {
        t("1. "),
        i(1, "Ordered list item content"),
        i(0),
    }),

    -- Markdown link
    s({
        trig = "link",
        dscr = "Markdown link [text](url)",
    }, {
        t("["),
        i(1, "Link Text"),
        t("]("),
        i(2, "https://example.com"),
        t(")"),
        i(0),
    }),

    -- Markdown image
    s({
        trig = "img",
        dscr = "Markdown image ![alt text](url)",
    }, {
        t("!["),
        i(1, "Alt Text"),
        t("]("),
        i(2, "path/to/image.jpg"),
        t(")"),
        i(0),
    }),

    -- Code block
    s({
        trig = "cb",
        dscr = "Markdown code block",
    }, {
        t("```"),
        i(1, "language"), -- Tabstop for language hint
        t("\n"),
        i(2, "your code here"),
        t("\n```"),
        i(0),
    }),

    -- Simple date snippet
    s({
        trig = "date",
        dscr = "Insert current date (YYYY-MM-DD)",
    }, {
        f(get_current_date, {}), -- Function node to insert current date
        i(0),
    }),

    -- Full timestamp
    s({
        trig = "ts",
        dscr = "Insert current timestamp (YYYY-MM-DD HH:MM)",
    }, {
        f(get_current_date, {}),
        t(" "),
        f(get_current_time, {}),
        i(0),
    }),

    -- Frontmatter (YAML) for Jekyll/Hugo etc.
    s({
        trig = "fm",
        dscr = "Insert Markdown Frontmatter",
    }, {
        t("---\n"),
        t("title: "),
        i(1, "My New Post"),
        t("\n"),
        t("date: "),
        f(get_current_date, {}),
        t("\n"),
        t("author: "),
        i(2, "Your Name"),
        t("\n"),
        t("tags: "),
        i(3, "tag1, tag2"),
        t("\n"),
        t("categories: "),
        i(4, "category1"),
        t("\n---\n\n"),
        i(0),
    }),

    -- Table of Contents
    s({
        trig = "toc",
        dscr = "Table of Contents placeholder",
    }, {
        t("## Table of Contents\n\n"),
        t("- [Introduction](#introduction)\n"),
        t("- [Section 1](#section-1)\n"),
        t("- [Section 2](#section-2)\n"),
        i(0),
    }),

    -- Definition list
    s({
        trig = "dl",
        dscr = "Definition list",
    }, {
        t("<dl>\n"),
        t("  <dt>"),
        i(1, "Term"),
        t("</dt>\n"),
        t("  <dd>"),
        i(2, "Definition"),
        t("</dd>\n"),
        t("</dl>"),
        i(0),
    }),

    -- Callout/Admonition (Common in some Markdown flavors like Obsidian or MkDocs)
    s({
        trig = "callout",
        dscr = "Insert a callout/admonition block",
    }, {
        t(">[!"),
        c(1, { t("NOTE"), t("TIP"), t("WARNING"), t("CAUTION"), t("IMPORTANT") }),
        t("] "),
        i(2, "Title (Optional)"),
        t("\n"),
        t(">\n"),
        t("> "),
        i(0, "Your callout content goes here."),
        t("\n"),
    }),
}
