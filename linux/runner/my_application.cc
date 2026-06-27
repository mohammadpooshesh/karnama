#include "my_application.h"

#include <flutter_linux/flutter_linux.h>
#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#endif

#include <libayatana-appindicator/app-indicator.h>
#ifdef HAVE_X11_IDLE
#include <X11/Xlib.h>
#include <X11/extensions/scrnsaver.h>
#endif

#include <cstring>
#include <string>

#include "flutter/generated_plugin_registrant.h"

struct _MyApplication {
  GtkApplication parent_instance;
  char** dart_entrypoint_arguments;

  GtkWindow* window;
  FlView* view;
  FlMethodChannel* method_channel;

  AppIndicator* app_indicator;
  guint blink_timer_id;
  gboolean blinking;
  gboolean blink_state;
  int timer_state;

  GdkWindow* gdk_window;
};

G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

static gboolean on_blink_timer(gpointer user_data) {
  MyApplication* self = MY_APPLICATION(user_data);
  self->blink_state = !self->blink_state;

  if (self->app_indicator) {
    if (self->blink_state) {
      app_indicator_set_icon_full(self->app_indicator, "karnama", "karnama");
    } else {
      app_indicator_set_icon_full(self->app_indicator, "karnama", "karnama");
    }
  }

  return G_SOURCE_CONTINUE;
}

static void tray_on_show_window(GtkMenuItem* item, gpointer user_data) {
  MyApplication* self = MY_APPLICATION(user_data);
  if (self->window) {
    gtk_window_deiconify(self->window);
    gtk_window_present(self->window);
  }
}

static void tray_on_quit(GtkMenuItem* item, gpointer user_data) {
  MyApplication* self = MY_APPLICATION(user_data);
  if (self->window) {
    gtk_widget_destroy(GTK_WIDGET(self->window));
    self->window = nullptr;
  }
}

static void tray_on_start_stop(GtkMenuItem* item, gpointer user_data) {
  MyApplication* self = MY_APPLICATION(user_data);
  if (self->method_channel) {
    g_autoptr(FlValue) args = fl_value_new_list();
    fl_method_channel_invoke_method(self->method_channel, "onTrayStop", args,
                                    nullptr, nullptr, nullptr);
  }
}

static void tray_on_pause(GtkMenuItem* item, gpointer user_data) {
  MyApplication* self = MY_APPLICATION(user_data);
  if (self->method_channel) {
    g_autoptr(FlValue) args = fl_value_new_list();
    fl_method_channel_invoke_method(self->method_channel, "onTrayPause", args,
                                    nullptr, nullptr, nullptr);
  }
}

static void setup_tray(MyApplication* self) {
  self->app_indicator = app_indicator_new(
      "karnama-tray",
      "karnama",
      APP_INDICATOR_CATEGORY_APPLICATION_STATUS);
  app_indicator_set_status(self->app_indicator,
                           APP_INDICATOR_STATUS_ACTIVE);
  app_indicator_set_title(self->app_indicator, "\u06A9\u0627\u0631\u0646\u0645\u0627");

  GtkWidget* menu = gtk_menu_new();

  GtkWidget* item_show = gtk_menu_item_new_with_label(
      "\u25A3  \u0628\u0627\u0632 \u06A9\u0631\u062F\u0646 \u06A9\u0627\u0631\u0646\u0645\u0627");
  g_signal_connect(item_show, "activate", G_CALLBACK(tray_on_show_window), self);
  gtk_menu_shell_append(GTK_MENU_SHELL(menu), item_show);

  GtkWidget* item_startstop = gtk_menu_item_new_with_label(
      "\u23F9  \u062A\u0648\u0642\u0641");
  g_signal_connect(item_startstop, "activate", G_CALLBACK(tray_on_start_stop), self);
  gtk_menu_shell_append(GTK_MENU_SHELL(menu), item_startstop);

  GtkWidget* item_pause = gtk_menu_item_new_with_label(
      "\u23F8  \u062A\u0648\u0642\u0641 \u0645\u0648\u0642\u062A");
  g_signal_connect(item_pause, "activate", G_CALLBACK(tray_on_pause), self);
  gtk_menu_shell_append(GTK_MENU_SHELL(menu), item_pause);

  GtkWidget* separator = gtk_separator_menu_item_new();
  gtk_menu_shell_append(GTK_MENU_SHELL(menu), separator);

  GtkWidget* item_quit = gtk_menu_item_new_with_label(
      "\u274C  \u062E\u0631\u0648\u062C");
  g_signal_connect(item_quit, "activate", G_CALLBACK(tray_on_quit), self);
  gtk_menu_shell_append(GTK_MENU_SHELL(menu), item_quit);

  gtk_widget_show_all(menu);
  app_indicator_set_menu(self->app_indicator, GTK_MENU(menu));
}

static int64_t get_idle_seconds_x11() {
#ifdef HAVE_X11_IDLE
  Display* dpy = XOpenDisplay(nullptr);
  if (!dpy) return 0;

  XScreenSaverInfo* info = XScreenSaverAllocInfo();
  if (!info) {
    XCloseDisplay(dpy);
    return 0;
  }

  XScreenSaverQueryInfo(dpy, DefaultRootWindow(dpy), info);
  int64_t idle_secs = info->idle / 1000;
  XFree(info);
  XCloseDisplay(dpy);
  return idle_secs;
#else
  return 0;
#endif
}

static void method_call_cb(FlMethodChannel* channel, FlMethodCall* method_call,
                            gpointer user_data) {
  MyApplication* self = MY_APPLICATION(user_data);
  const gchar* method = fl_method_call_get_name(method_call);
  FlValue* args = fl_method_call_get_args(method_call);
  g_autoptr(FlMethodResponse) response = nullptr;

  if (g_strcmp0(method, "getHwnd") == 0) {
    int64_t hwnd = 0;
    if (self->gdk_window) {
#ifdef GDK_WINDOWING_X11
      if (GDK_IS_X11_WINDOW(self->gdk_window)) {
        hwnd = (int64_t)gdk_x11_window_get_xid(self->gdk_window);
      }
#endif
    }
    response = FL_METHOD_RESPONSE(
        fl_method_success_response_new(fl_value_new_int(hwnd)));
  } else if (g_strcmp0(method, "setWindowTitle") == 0) {
    if (args && fl_value_get_length(args) > 0) {
      const char* title = fl_value_get_string(fl_value_get_list_value(args, 0));
      if (self->window && title) {
        gtk_window_set_title(self->window, title);
      }
    }
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
  } else if (g_strcmp0(method, "setTrayTooltip") == 0) {
    if (args && fl_value_get_length(args) > 0) {
      const char* text = fl_value_get_string(fl_value_get_list_value(args, 0));
      if (self->app_indicator && text) {
        app_indicator_set_title(self->app_indicator, text);
      }
    }
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
  } else if (g_strcmp0(method, "startBlink") == 0) {
    if (!self->blinking) {
      self->blinking = TRUE;
      self->blink_state = FALSE;
      self->blink_timer_id = g_timeout_add(1000, on_blink_timer, self);
    }
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
  } else if (g_strcmp0(method, "stopBlink") == 0) {
    if (self->blinking) {
      self->blinking = FALSE;
      if (self->blink_timer_id > 0) {
        g_source_remove(self->blink_timer_id);
        self->blink_timer_id = 0;
      }
      if (self->app_indicator) {
        app_indicator_set_icon_full(self->app_indicator, "karnama", "karnama");
      }
    }
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
  } else if (g_strcmp0(method, "showWindow") == 0) {
    if (self->window) {
      gtk_window_deiconify(self->window);
      gtk_window_present(self->window);
    }
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
  } else if (g_strcmp0(method, "minimizeWindow") == 0) {
    if (self->window) {
      gtk_window_iconify(self->window);
    }
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
  } else if (g_strcmp0(method, "startWindowDrag") == 0) {
    if (self->gdk_window) {
      GdkSeat* seat =
          gdk_display_get_default_seat(gdk_window_get_display(self->gdk_window));
      GdkDevice* pointer = gdk_seat_get_pointer(seat);

      gint root_x, root_y;
      gdk_window_get_root_origin(self->gdk_window, &root_x, &root_y);

      gint pointer_x, pointer_y;
      gdk_device_get_position(pointer, nullptr, &pointer_x, &pointer_y);

      gint offset_x = pointer_x - root_x;
      gint offset_y = pointer_y - root_y;

      gint64 start_time = g_get_monotonic_time();
      while (g_get_monotonic_time() - start_time < 3000000) {
        gint px, py;
        gdk_device_get_position(pointer, nullptr, &px, &py);
        gtk_window_move(self->window, px - offset_x, py - offset_y);
        while (gdk_events_pending()) {
          gtk_main_iteration();
        }
      }
    }
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
  } else if (g_strcmp0(method, "closeWindow") == 0) {
    if (self->window) {
      gtk_widget_destroy(GTK_WIDGET(self->window));
      self->window = nullptr;
    }
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
  } else if (g_strcmp0(method, "getIdleSeconds") == 0) {
    int64_t idle_secs = get_idle_seconds_x11();
    response = FL_METHOD_RESPONSE(
        fl_method_success_response_new(fl_value_new_int(idle_secs)));
  } else if (g_strcmp0(method, "setTimerState") == 0) {
    if (args && fl_value_get_length(args) > 0) {
      self->timer_state = fl_value_get_int(fl_value_get_list_value(args, 0));
    }
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
  } else {
    response = FL_METHOD_RESPONSE(
        fl_method_not_implemented_response_new());
  }

  fl_method_call_respond(method_call, response, nullptr);
}

static void first_frame_cb(MyApplication* self, FlView* view) {
  gtk_widget_show(gtk_widget_get_toplevel(GTK_WIDGET(view)));
}

static void my_application_activate(GApplication* application) {
  MyApplication* self = MY_APPLICATION(application);
  self->window = GTK_WINDOW(
      gtk_application_window_new(GTK_APPLICATION(application)));

  gtk_window_set_title(self->window, "\u06A9\u0627\u0631\u0646\u0645\u0627");
  gtk_window_set_default_size(self->window, 427, 720);
  gtk_window_set_resizable(self->window, FALSE);

  g_autoptr(FlDartProject) project = fl_dart_project_new();
  fl_dart_project_set_dart_entrypoint_arguments(
      project, self->dart_entrypoint_arguments);

  self->view = fl_view_new(project);
  GdkRGBA background_color;
  gdk_rgba_parse(&background_color, "#000000");
  fl_view_set_background_color(self->view, &background_color);
  gtk_widget_show(GTK_WIDGET(self->view));
  gtk_container_add(GTK_CONTAINER(self->window), GTK_WIDGET(self->view));

  g_signal_connect_swapped(self->view, "first-frame",
                           G_CALLBACK(first_frame_cb), self);
  gtk_widget_realize(GTK_WIDGET(self->view));

  self->gdk_window = gtk_widget_get_window(GTK_WIDGET(self->view));

  fl_register_plugins(FL_PLUGIN_REGISTRY(self->view));

  self->method_channel = fl_method_channel_new(
      fl_engine_get_binary_messenger(fl_view_get_engine(self->view)),
      "karnama/window",
      FL_METHOD_CODEC(fl_standard_method_codec_new()));
  fl_method_channel_set_method_call_handler(
      self->method_channel, method_call_cb, self, nullptr);

  setup_tray(self);

  gtk_widget_grab_focus(GTK_WIDGET(self->view));
  gtk_widget_show_all(GTK_WIDGET(self->window));
}

static gboolean my_application_local_command_line(GApplication* application,
                                                  gchar*** arguments,
                                                  int* exit_status) {
  MyApplication* self = MY_APPLICATION(application);
  self->dart_entrypoint_arguments = g_strdupv(*arguments + 1);

  g_autoptr(GError) error = nullptr;
  if (!g_application_register(application, nullptr, &error)) {
    g_warning("Failed to register: %s", error->message);
    *exit_status = 1;
    return TRUE;
  }

  g_application_activate(application);
  *exit_status = 0;

  return TRUE;
}

static void my_application_startup(GApplication* application) {
  G_APPLICATION_CLASS(my_application_parent_class)->startup(application);
}

static void my_application_shutdown(GApplication* application) {
  MyApplication* self = MY_APPLICATION(application);

  if (self->blinking && self->blink_timer_id > 0) {
    g_source_remove(self->blink_timer_id);
    self->blink_timer_id = 0;
  }

  G_APPLICATION_CLASS(my_application_parent_class)->shutdown(application);
}

static void my_application_dispose(GObject* object) {
  MyApplication* self = MY_APPLICATION(object);
  g_clear_pointer(&self->dart_entrypoint_arguments, g_strfreev);
  G_OBJECT_CLASS(my_application_parent_class)->dispose(object);
}

static void my_application_class_init(MyApplicationClass* klass) {
  G_APPLICATION_CLASS(klass)->activate = my_application_activate;
  G_APPLICATION_CLASS(klass)->local_command_line =
      my_application_local_command_line;
  G_APPLICATION_CLASS(klass)->startup = my_application_startup;
  G_APPLICATION_CLASS(klass)->shutdown = my_application_shutdown;
  G_OBJECT_CLASS(klass)->dispose = my_application_dispose;
}

static void my_application_init(MyApplication* self) {
  self->window = nullptr;
  self->view = nullptr;
  self->method_channel = nullptr;
  self->app_indicator = nullptr;
  self->blink_timer_id = 0;
  self->blinking = FALSE;
  self->blink_state = FALSE;
  self->timer_state = 0;
  self->gdk_window = nullptr;
}

MyApplication* my_application_new() {
  g_set_prgname(APPLICATION_ID);
  return MY_APPLICATION(g_object_new(my_application_get_type(),
                                     "application-id", APPLICATION_ID, "flags",
                                     G_APPLICATION_NON_UNIQUE, nullptr));
}
