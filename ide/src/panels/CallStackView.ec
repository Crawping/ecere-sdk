#include <stdarg.h>

import "ecere"
import "CodeEditor"

class CallStackView : Window
{
   visible = false;
   borderStyle = sizableDeep;
   background = { 224, 224, 224 };
   hasClose = true;
   mergeMenus = false;
   text = $"Call Stack";
   menu = Menu { };
   anchor = Anchor { left = 0, right = 0.2, top = 0 };
   size.h = 200;

   virtual void OnSelectFrame(int frameIndex);
   virtual void OnToggleBreakpoint();

   bool moved, logging;
   FindDialog findDialog { master = this, editBox = editBox, isModal = true, autoCreate = false, text = $"Find" };

   EditBox editBox
   {
      parent = this, freeCaret = true, autoEmpty = true, multiLine = true, readOnly = true;
      hasVertScroll = true, hasHorzScroll = true, borderStyle = none;
      anchor = Anchor { left = 20, top = 0, right = 0, bottom = 0 };
      /*
      background = colorScheme.viewsBackground;
      foreground = colorScheme.viewsText;
      selectionColor = colorScheme.selectionColor;
      selectionText = colorScheme.selectionText;
      */

      bool NotifyDoubleClick(EditBox editBox, EditLine line, Modifiers mods)
      {
         int frameIndex = -1;
         if(strcmp(editBox.line.text, "..."))
            frameIndex = atoi(editBox.line.text);
         OnSelectFrame(frameIndex);
         return false;
      }

      bool NotifyKeyDown(EditBox editBox, Key key, unichar ch)
      {
         if(key == enter || key == keyPadEnter)
         {
            int frameIndex = -1;
            if(strcmp(editBox.line.text, "..."))
               frameIndex = atoi(editBox.line.text);
            OnSelectFrame(frameIndex);
            return false;
         }
         if(key == f9)
         {
            OnToggleBreakpoint();
            return false;
         }
         return true;
      }

      void OnVScroll(ScrollBarAction action, int position, Key key)
      {
         if(anchor.left.distance)
         {
            Box box { 0, 0, anchor.left.distance-1, parent.clientSize.h - 1 };
            parent.Update(box);
         }
         EditBox::OnVScroll(action, position, key);
      }
   };

   Menu editMenu { menu, $"Edit", e };
   MenuItem item;

   MenuItem copyItem
   {
      editMenu, $"Copy", c, ctrlC;
      bool NotifySelect(MenuItem selection, Modifiers mods)
      {
         editBox.Copy();
         return true;
      }
   };
   MenuDivider { editMenu };
   MenuItem { editMenu, $"Find Previous", e, Key { f3, shift = true }, NotifySelect = MenuEditFind, id = 0 };
   MenuItem { editMenu, $"Find Next", n, f3, NotifySelect = MenuEditFind, id = 1 };
   MenuItem { editMenu, $"Find", f, ctrlF, NotifySelect = MenuEditFind, id = 2 };

   bool MenuEditFind(MenuItem selection, Modifiers mods)
   {
      int64 id = selection.id;
      const char * searchString = findDialog.searchString;
      if(id != 2 && searchString[0])
      {
         editBox.Find(searchString, findDialog.wholeWord, findDialog.matchCase, id != 0);
         return true;
      }
      findDialog.Create();
      return true;
   }

   void Logf(const char * format, ...)
   {
      char string[MAX_F_STRING*10];
      va_list args;
      va_start(args, format);
      vsnprintf(string, sizeof(string), format, args);
      string[sizeof(string)-1] = 0;
      va_end(args);

      Log(string);
   }

   void LogRaw(const char * entry)
   {
      Log(entry);
   }
   void Log(const char * string)
   {
      EditLine line1;
      EditLine line2;
      int x1, y1, x2, y2;
      Point scroll;
      logging = true;
      if(moved)
      {
         editBox.GetSelPos(&line1, &y1, &x1, &line2, &y2, &x2, false);
         scroll = editBox.scroll;
      }
      editBox.End();
      editBox.PutS(string);
      editBox.Update(null);
      if(moved)
      {
         editBox.scroll = scroll;
         editBox.SetSelPos(line1, y1, x1, line2, y2, x2);
      }
      logging = false;
   }
   void Clear()
   {
      editBox.Clear();
      moved = false;
   }
   void Home()
   {
      editBox.Home();
   }
   void Show()
   {
      visible = true;
      ide.RepositionWindows(false);
      Activate();
   }
}
