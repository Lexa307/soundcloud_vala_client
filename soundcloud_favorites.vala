using Gtk;

public class UserSearch : Window {
    public UserSearch (/*Soup.Session session*/) {
        this.title = "Выбор пользователя Soundcloud";
        try {
            this.icon = new Gdk.Pixbuf.from_file ("./assets/img/cloud-logo.png");
        } catch (Error e) {
            stderr.printf (@"Can not load icon: $(e.message)");
        }
        set_default_size(450, 20);
        var search_entry = new Entry ();
        search_entry.set_placeholder_text ("Soundcloud nickname");
        var search_label = new Label.with_mnemonic ("Введите Soundcloud nickname:");
    
        var button = new Button.with_label ("Поиск");
        var query_str = "https://soundcloud.com/search/people?q=";
        var hbox = new Box (Orientation.HORIZONTAL, 20);
        hbox.pack_start (search_label, false, true, 0);
        hbox.pack_start (search_entry, false, true, 0);
        hbox.pack_start (button, false, true, 0);
        this.add(hbox);

        var session = new Soup.Session (); //https://soundcloud.com/connect old https://api-auth.soundcloud.com/connect/session https://soundcloud.com/search?q=Lexa307
        var connect_url = "https://soundcloud.com/connect?client_id=wemqLM56wkD5McvdTn2KaZmQgQ0FC8Jg";
        var auth_message = new Soup.Message ("GET", connect_url);
        session.send_message (auth_message);
        //  auth_message.response_headers.foreach ((name, val) => {
        //      stdout.printf ("Name: %s -> Value: %s\n", name, val);
        //  });
        
        button.clicked.connect (() => {

            
            //  print("clicked");
            //  var auth_message = new Soup.Message ("GET", connect_url);
            var message = new Soup.Message ("GET", query_str + search_entry.get_text() );
            //  stdout.printf(query_str + search_entry.get_text() + "?client_id=wemqLM56wkD5McvdTn2KaZmQgQ0FC8Jg\n" );
            // send the HTTP request and wait for response
            
            session.send_message (message);
            //  stdout.printf(message.response_body.data);
            //  stdout.write(message.response_body.data);
            string data = (string) message.response_body.data;
            //  print(data);
            string usr_start = "/user-";
            string usr_end = ">";
            int usr_start_index = data.index_of (usr_start);
            if (usr_start_index == -1) {
                return;
            } else {
                usr_start_index += 6;
            }
            print(usr_start_index.to_string() + "\n");
            int usr_end_index = data.index_of(usr_end, usr_start_index) - 1;
            //  print(usr_end_index.to_string()+ "\n");
            string result = data.substring(usr_start_index , usr_end_index - usr_start_index  );
            //  print(result);
            //  print(query_str + search_entry.get_text() + "?client_id=wemqLM56wkD5McvdTn2KaZmQgQ0FC8Jg&limit=20&offset=0");
            //  message.response_headers.foreach ((name, val) => {
            //      stdout.printf ("Name: %s -> Value: %s\n", name, val);
            //  });
        
            //  stdout.printf ("Message length: %lld\n%s\n", message.response_body.length, message.response_body.data);
        
            var sample = new TrackList (session, result);
            sample.show_all ();
            this.destroy();
        });
        //  this.add (search_label);
        //  this.add (button);
    
    }
}

public class TrackList : Window {

    public TrackList (Soup.Session session, string user_id) {
        this.title = "Soundcloud favorites v0.1";
        try {
            this.icon = new Gdk.Pixbuf.from_file ("./assets/img/cloud-logo.png");
        } catch (Error e) {
            stderr.printf (@"Can not load icon: $(e.message)");
        }
        set_default_size(250, 100);
        var view = new TreeView();
        setup_treeview(view, user_id);
        add(view);
        this.destroy.connect(Gtk.main_quit);
    }

    private void setup_treeview (TreeView view, string user_id) {
        
        var connect_url = "https://api-auth.soundcloud.com/connect/session?client_id=wemqLM56wkD5McvdTn2KaZmQgQ0FC8Jg";
        var url = "https://api-v2.soundcloud.com/users/" + user_id + "/track_likes?client_id=wemqLM56wkD5McvdTn2KaZmQgQ0FC8Jg&limit=24&offset=0&linked_partitioning=1";
        var session = new Soup.Session ();
        var auth_message = new Soup.Message ("GET", connect_url);
        var message = new Soup.Message ("GET", url);
        
        // send the HTTP request and wait for response
        session.send_message (auth_message);
        session.send_message (message);

        var listmodel = new Gtk.ListStore (4, typeof (string), typeof (string),
        typeof (string), typeof (string));
        view.set_model (listmodel);

        view.insert_column_with_attributes (-1, "Song Name", new CellRendererText (), "text", 0);
        view.insert_column_with_attributes (-1, "Artist", new CellRendererText (), "text", 1);

        var cell = new CellRendererText ();
        cell.set ("foreground_set", true);
        view.insert_column_with_attributes (-1, "Likes", cell, "text", 2, "foreground", 3);

        TreeIter iter;

        try {
            var parser = new Json.Parser ();
            parser.load_from_data ((string) message.response_body.flatten().data, -1);
            var root_object = parser.get_root().get_object();
            //  print(@"$((string) root_object)\n");
            var track_array = root_object.get_array_member("collection");
            int i = 1;

            foreach (unowned Json.Node item in track_array.get_elements ()) {
                //  process_role (item, i);
                var obj = item.get_object();
                var track = obj.get_object_member("track");
                var str = track.get_string_member("title");
                var str_like = track.get_int_member("likes_count");
                var user = track.get_object_member("user");
                var username = user.get_string_member("username");
                //  print(i.to_string() + "\n");
                i++;
                listmodel.append (out iter);
                listmodel.set (iter, 0, str, 1, username, 2, str_like.to_string(), 3, "green");
            }
        
        } catch (Error e) {
            stderr.printf ("I guess something is not working...\n");
        }        
    }

    public class Connection {
        public Soup.Session session;
        public Connection () {
            this.session = new Soup.Session ();
            var connect_url = "https://api-auth.soundcloud.com/connect/session?client_id=wemqLM56wkD5McvdTn2KaZmQgQ0FC8Jg";
            var auth_message = new Soup.Message ("GET", connect_url);
            session.send_message (auth_message);
            stdout.write(auth_message.response_body.flatten().data);
        }
    }

    public static int main (string[] args) {
        Gtk.init (ref args);
        // register App to soundcloud api
        //  var session = new Soup.Session ();
        Connection connection = new Connection ();
        var userSearcher = new UserSearch (/*connection.session*/);
        userSearcher.show_all ();

        Gtk.main ();

        return 0;
    }
    
}
