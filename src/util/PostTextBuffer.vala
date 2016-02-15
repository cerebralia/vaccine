public class Vaccine.PostTextBuffer : Object {
    private const MarkupParser parser = {
        visit_start,
        visit_end,
        visit_text,
        visit_passthrough,
        error
    };

    //private uint a_tag_level = 0; // handles nested <a> tags...thanks mods
    private MarkupParseContext ctx;
    private string src;
    private Gtk.TextBuffer buffer;
    private Gtk.TextIter iter;

    private string current_tag = null;

    void visit_start (MarkupParseContext context, string elem, string[] attrs, string[] vals) throws MarkupError {
        if (elem == "pre")
            current_tag = "code";
        if (elem == "b")
            current_tag = "bold";
        if (elem == "u")
            current_tag = "underline";

        for (int i = 0; i < attrs.length; ++i) {
            if (elem == "span" && attrs[i] == "class" && vals[i] == "quote")
                current_tag = "greentext";
            if (elem == "a" && attrs[i] == "class" && vals[i] == "quotelink")
                current_tag = "link";
        }
    }

    void visit_text (MarkupParseContext context, string text, size_t text_len) throws MarkupError {
        var link_regex = /(\w+:\/\/\S*)/;
        var tokens = link_regex.split (text);
        foreach (var elem in tokens) {
            if (link_regex.match (elem))
                buffer.insert_with_tags_by_name (ref iter, elem, -1, "link", current_tag);
            else
                buffer.insert_with_tags_by_name (ref iter, elem, -1, current_tag);
        }
    }

    void visit_end (MarkupParseContext context, string elem) throws MarkupError {
        current_tag = null;
    }

    void visit_passthrough (MarkupParseContext context, string passthrough_text, size_t text_len) throws MarkupError {
        debug (@"visit_passthrough: $passthrough_text\n");
    }

    void error (MarkupParseContext context, Error error)  {
        debug (@"error: $(error.message)\n");
    }

    public PostTextBuffer (string com) {
        this.src = com;
        ctx = new MarkupParseContext(parser, 0, this, null);
    }

    public void fill_text_buffer (Gtk.TextBuffer buffer) throws MarkupError {
        this.buffer = buffer;
        buffer.get_iter_at_offset (out this.iter, 0);
        this.ctx.parse ("<_top_level>" + src + "</_top_level>", -1); // requires a top-level element
        // print (@"\n\x1b[35m==========================================\x1b[0m\n$src\n\t\t\t\t\x1b[44mv\x1b[0m\n$(buffer.text)\n\n");
    }
}
