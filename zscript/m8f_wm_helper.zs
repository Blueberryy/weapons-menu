class WMZscriptHelper play
{

  // public section ////////////////////////////////////////////////////////////

  static void TellAmmo(Actor activator, string weaponClass, bool showSecond)
  {
    if (!activator) { return; }
    PlayerInfo player = activator.player;
    if (!player) { return; }

    Weapon w = Weapon(activator.FindInventory(weaponClass));
    if (!w)
    {
      SendResultString(player, "");
      return;
    }

    string message = "";

    Ammo amm1 = w.Ammo1;
    if (amm1)
    {
      message = String.Format("%d/%d", amm1.amount, amm1.maxAmount);
    }

    Ammo amm2 = w.Ammo2;
    if (showSecond && amm2 && amm1 != amm2)
    {
      if (message.length() > 0) { message.AppendFormat(" - "); }
      message.AppendFormat("%d/%d", amm2.amount, amm2.maxAmount);
    }

    SendResultString(player, message);
  }

  static void HasAmmo(Actor activator, string weaponClass)
  {
    if (!activator) { return; }
    PlayerInfo player = activator.player;
    if (!player) { return; }

    Weapon w = Weapon(activator.FindInventory(weaponClass));
    if (!w)
    {
      SendResultInt(player, 0);
      return;
    }

    bool result   = false;
    Ammo amm1     = w.Ammo1;
    Ammo amm2     = w.Ammo2;
    bool hasAmmo1 = (amm1 != NULL);
    bool hasAmmo2 = (amm2 != NULL);

    if (!hasAmmo1 && !hasAmmo2) { result = true; }
    else
    {
      if (hasAmmo1) { result |= (amm1.amount >= w.AmmoUse1) && (amm1.amount > 0); }
      if (hasAmmo2) { result |= (amm2.amount >= w.AmmoUse2) && (amm2.amount > 0); }
    }

    SendResultInt(player, result);
  }

  static void IsWeaponReady(Actor activator)
  {
    if (!activator) { return; }
    PlayerInfo player = activator.player;
    if (!player) { return; }

    bool isReady = (player.WeaponState & WF_WEAPONREADY)
      || (player.WeaponState & WF_WEAPONREADYALT);
    SendResultInt(player, isReady);
  }

  static void IsWeaponDeselectable(Actor activator)
  {
    if (!activator) { return; }
    PlayerInfo player = activator.player;
    if (!player) { return; }

    bool isDeselectable = player.WeaponState & WF_WEAPONSWITCHOK;
    SendResultInt(player, isDeselectable);
  }

  static void IsWeaponBeingDeselected(Actor activator)
  {
    if (!activator) { return; }
    let player = activator.player;
    if (!player) { return; }

    bool isDeselected = player.PendingWeapon.GetClassName() != "Object";
    SendResultInt(player, isDeselected);
  }

  static void FireWeapon(Actor activator)
  {
    if (!activator) { return; }

    PlayerPawn pawn = PlayerPawn(activator);
    pawn.FireWeapon(NULL);
  }

  static void FireWeaponAlt(Actor activator)
  {
    if (!activator) { return; }

    PlayerPawn pawn = PlayerPawn(activator);
    pawn.FireWeaponAlt(NULL);
  }

  static void GetInventoryList(Actor activator)
  {
    if (!activator) { return; }
    let player = activator.player;
    if (!player) { return; }

    string inventoryContents = "";
    int nClasses = AllActorClasses.Size();

    for (int i = 0; i < nClasses; ++i)
    {
      let type = (class<Inventory>)(AllActorClasses[i]);
      if (type == NULL) { continue; }

      readonly<Inventory> inv = GetDefaultByType(type);
      if (!inv.bINVBAR || inv.bAUTOACTIVATE) { continue; }

      string className = inv.GetClassName();
      string tag       = m8f_wm_String.Beautify(inv.GetTag());
      inventoryContents.AppendFormat("%s>%s>", className, tag);
    }

    SendResultString(player, inventoryContents);
  }

  static void GetInventoryTag(Actor activator, string itemClass)
  {
    if (!activator) { return; }
    let player = activator.player;
    if (!player) { return; }

    class<Inventory> type = itemClass;
    if (!type)
    {
      Console.Printf("Unknown inventory type: %s", itemClass);
      SendResultString(player, "unknown");
      return;
    }

    readonly<Inventory> defaultItem = GetDefaultByType(type);
    if (!defaultItem)
    {
      Console.Printf("Unknown inventory type: %s", itemClass);
      SendResultString(player, "unknown");
      return;
    }

    string tag = defaultItem.GetTag();

    SendResultString(player, tag);
  }

  static void GetSelectedInventory(Actor activator)
  {
    if (!activator) { return; }
    let player = activator.player;
    if (!player) { return; }

    PlayerPawn pawn = PlayerPawn(activator);

    if (pawn && pawn.InvSel != NULL)
    {
      SendResultString(player, pawn.InvSel.GetClassName());
    }
    else
    {
      SendResultString(player, "wm_none");
    }
  }

  static void SetSelectedInventory(Actor activator, string itemClass)
  {
    if (!activator) { return; }

    PlayerPawn pawn = PlayerPawn(activator);
    pawn.InvSel = pawn.FindInventory(itemClass);
  }

  static
  void GetWeaponList(Actor activator)
  {
    if (!activator) { return; }
    let player = activator.player;
    if (!player) { return; }

    int nClasses = AllActorClasses.Size();

    m8f_wm_WeaponInfo info;

    for (int i = 0; i < nClasses; ++i)
    {
      let type = (class<Weapon>)(AllActorClasses[i]);

      if (type == NULL || type == "Weapon") { continue; }

      // Don't list replaced weapons unless the replacement was done by Dehacked.
      let rep = Actor.GetReplacement(type);

      if (rep != type && !(rep is "DehackedPickup")) { continue; }

      bool located;
      int  slot;
      int  priority;
      [located, slot, priority] = player.weapons.LocateWeapon(type);

      // List the weapon only if it is set in a weapon slot.
      if (!located) { continue; }

      readonly<Weapon> def = GetDefaultByType(type);
      if (!def.CanPickup(activator)) { continue; }

      string className = type.GetClassName();
      string tag       = m8f_wm_String.Beautify(def.GetTag());
      // just to be sure that "serializing" will not break
      tag.Replace(">", " ");

      info.push(className, tag, slot, priority);
    }

    sortWeapons(info);

    int    nWeapons   = info.classes.size();
    string weaponData = "";

    for (int i = 0; i < nWeapons; ++i)
    {
      weaponData.AppendFormat( "%s>%s>%d>%d>"
                             , info.classes[i]
                             , info.tags[i]
                             , info.slots[i]
                             , info.priorities[i]
                             );
    }

    SendResultString(player, weaponData);
  }

  static void SetZoomFactor( Actor  activator
                           , double zoom
                           , string weaponClass
                           , bool   lowerWeapon
                           , bool   isZoomed
                           , bool   changeZoom
                           )
  {
    if (!activator) { return; }

    Weapon w = Weapon(activator.FindInventory(weaponClass));
    if (!w) { return; }

    if (changeZoom)
    {
      zoom = 1 / clamp(zoom, 0.1, 50.0);
      w.FOVScale = zoom;
    }

    if (lowerWeapon)
    {
      int yShift = 16;
      if (!isZoomed) { w.YAdjust -= yShift; }
      else           { w.YAdjust += yShift; }
    }
  }

  static void GetWeaponIcon(Actor activator, string weaponClass)
  {
    if (!activator) { return; }
    let player = activator.player;
    if (!player) { return; }

    weaponClass.ToLower();

    string specialIcon = m8f_wm_Data.get().icons.get(weaponClass);
    if (specialIcon.Length() != 0)
    {
      SendResultString(player, specialIcon);
      return;
    }

    Weapon w = Weapon(activator.FindInventory(weaponClass));
    if (!w)
    {
      SendResultString(player, placeholder);
      return;
    }

    TextureID iconID = w.SpawnState.GetSpriteTexture(0);
    string    icon   = TexMan.GetName(iconID);

    if (icon == "TNT1A0")   { icon = TexMan.GetName(w.icon); }
    if (icon == "TNT1A0")   { icon = placeholder; }
    if (icon == "ALTHUDCF") { icon = placeholder; }

    SendResultString(player, icon);
  }

  // private section ///////////////////////////////////////////////////////////

  private static void SendResultString(PlayerInfo player, string result)
  {
    if (!player) { return; }
    CVar messageCVar = CVar.GetCVar("m8f_wm_ResultString", player);
    messageCVar.SetString(result);
  }

  private static void SendResultInt(PlayerInfo player, int result)
  {
    if (!player) { return; }
    CVar messageCVar = CVar.GetCVar("m8f_wm_ResultInt", player);
    messageCVar.SetInt(result);
  }

  private static void SendResultDouble(PlayerInfo player, double result)
  {
    if (!player) { return; }
    CVar messageCVar = CVar.GetCVar("m8f_wm_ResultInt", player);
    messageCVar.SetFloat(result);
  }

  private static void sortWeapons(m8f_wm_WeaponInfo info)
  {
    int nWeapons = info.classes.size();

    quickSortWeapons(info, 0, nWeapons - 1);
  }

  private static void quickSortWeapons(m8f_wm_WeaponInfo info, int lo, int hi)
  {
    if (lo < hi)
    {
      int p = quickSortWeaponsPartition(info, lo, hi);
      quickSortWeapons(info, lo,    p - 1);
      quickSortWeapons(info, p + 1, hi   );
    }
  }

  private static int quickSortWeaponsPartition(m8f_wm_WeaponInfo info, int lo, int hi)
  {
    int pivot = measure(info, hi);
    int i     = lo - 1;

    for (int j = lo; j <= hi - 1; ++j)
    {
      if (measure(info, j) > pivot)
      {
        ++i;
        info.swap(i, j);
      }
    }
    info.swap(i + 1, hi);

    return i + 1;
  }

  private static int measure(m8f_wm_WeaponInfo info, int i)
  {
    int slot = info.slots[i];
    if (slot == 0) { slot = 99; }

    slot = 99 - slot; // reverse order

    int measure = slot * 100 + info.priorities[i];

    return measure;
  }

  // constants: ////////////////////////////////////////////////////////////////

  const placeholder = "NOWEAPONOFF";

} // class WMZscriptHelper

struct m8f_wm_WeaponInfo
{

  // public: ///////////////////////////////////////////////////////////////////

  void push(string className, string tag, int slot, int priority)
  {
    classes   .push(className);
    tags      .push(tag);
    slots     .push(slot);
    priorities.push(priority);
  }

  void swap(int i, int j)
  {
    {
      string tmp = classes[i];
      classes[i] = classes[j];
      classes[j] = tmp;
    }
    {
      string tmp = tags[i];
      tags[i]    = tags[j];
      tags[j]    = tmp;
    }
    {
      int tmp  = slots[i];
      slots[i] = slots[j];
      slots[j] = tmp;
    }
    {
      int tmp = priorities[i];
      priorities[i] = priorities[j];
      priorities[j] = tmp;
    }
  }

  // public: ///////////////////////////////////////////////////////////////////

  Array<string> classes;
  Array<string> tags;
  Array<int>    slots;
  Array<int>    priorities;

} // struct m8f_wm_WeaponInfo
