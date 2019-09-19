module farfadet.gui.elements;

import std.file;
import atelier;
import farfadet.common;

private final class ImgElementGui: GuiElement {
    Label label;
    InputField inputField;
    bool isEditingName, isFirstClick = true;

    ElementData data;

    this() {
        label = new Label("untitled");
        label.setAlign(GuiAlignX.Center, GuiAlignY.Center);
        addChildGui(label);
        size = label.size;

        data = new ElementData;
    }

    override void onCallback(string id) {
        if(id != "editname")
            return;
        applyEditedName();        
    }

    override void update(float deltaTime) {
        if(!isSelected && isEditingName) {
            applyEditedName();
        }
        else if(!isSelected) {
            isFirstClick = true;
        }
    }

    void applyEditedName() {
        if(!isEditingName)
            throw new Exception("The element is not in an editing state");
        isEditingName = false;
        isFirstClick = true;

        data.name = inputField.text;
        label.text = data.name;
        removeChildrenGuis();
        addChildGui(label);
    }

    override void onSubmit() {
        if(isSelected && !isEditingName) {
            if(!isFirstClick) {
                isEditingName = true;
                removeChildrenGuis();
                inputField = new InputField(size, label.text != "untitled" ? label.text : "");
                inputField.setAlign(GuiAlignX.Center, GuiAlignY.Center);
                inputField.setCallback(this, "editname");
                inputField.hasFocus = true;
                addChildGui(inputField);
            }
            isFirstClick = false;
        }
        triggerCallback();
    }

    override void draw() {
        Color color;
        final switch(data.type) with(ElementType) {
        case SpriteType:
            color = isSelected ? Color.fromRGB(0x9EFFCF) : Color.fromRGB(0x7CCCCB);
            break;
        case TilesetType:
            color = isSelected ? Color.fromRGB(0x9EBBFF) : Color.fromRGB(0x8B7CCC);
            break;
        case BorderedBrushType:
            color = isSelected ? Color.fromRGB(0xF59EFF) : Color.fromRGB(0xCC7CAE);
            break;
        case BorderlessBrushType:
            color = isSelected ? Color.fromRGB(0xFFA89E) : Color.fromRGB(0xCCAB7C);
            break;
        case NinePatchType:
            color = isSelected ? Color.fromRGB(0xE2FF9E) : Color.fromRGB(0x8ECC7C);
            break;
        }
        drawFilledRect(origin, size, color);
    }
}

final class ElementsListGui: VList {
    this() {
        float sz = (screenWidth - screenHeight) / 2f;
        super(Vec2f(sz, screenHeight - sz - 80f));
    }

    override void onCallback(string id) {
        auto elementId = selected();
        super.onCallback(id);
        if(elementId != selected())
            triggerCallback();
    }

    override void update(float deltaTime) {
        super.update(deltaTime);
        if(getKeyDown("up")) {
            selected(selected() - 1);
            triggerCallback();
        }
        if(getKeyDown("down")) {
            selected(selected() + 1);      
            triggerCallback();            
        }
    }

    override void draw() {
        drawFilledRect(origin, size, Color(.08f, .09f, .11f));
    }

    void moveUpElement() {
		auto elements = getList();
        auto id = selected();

        if(!elements.length)
            return;
        
		if(id >= elements.length)
			throw new Exception("Element id out of bounds");
		else if(id == 0u)
			return;
		else if(id + 1 == elements.length)
			elements = elements[0..$-2] ~ [elements[$-1], elements[$-2]];
		else
			elements = elements[0..id-1] ~ [elements[id], elements[id-1]] ~ elements[id+1..$];

		removeChildrenGuis();
		foreach(element; elements)
			addChildGui(element);
        selected(id - 1);

        setElements();
        triggerCallback();
	}

    void moveDownElement() {
		auto elements = getList();
        auto id = selected();

        if(!elements.length)
            return;

		if(id >= elements.length)
			throw new Exception("Element id out of bounds");
		else if(id + 1 == elements.length)
			return;
		else if(id == 0u)
			elements = [elements[1], elements[0]] ~ elements[2..$];
		else
			elements = elements[0..id] ~ [elements[id+1], elements[id]] ~ elements[id+2..$];

		removeChildrenGuis();
		foreach(element; elements)
			addChildGui(element);
        selected(id + 1);

        setElements();
        triggerCallback();
    }

    void addElement() {
        auto newElement = new ImgElementGui;
        auto elements = getList();
        auto id = selected();

        if(elements.length == 0u) {
            elements ~= newElement;
            id = 0u;
        }
        else if(id >= elements.length)
            throw new Exception("Element id out of bounds");
        else if(id + 1 == elements.length) {
            elements ~= newElement;
            id ++;
        }
        else if(id == 0u) {
            elements = [elements[0], newElement] ~ elements[1..$];
            id = 1u;
        }
        else {
            elements = elements[0..id] ~ newElement ~ elements[id..$];
            id ++;
        }

        removeChildrenGuis();
        foreach(element; elements)
            addChildGui(element);
        selected(id);

        setElements();
        triggerCallback();
    }

    void dupElement() {
        auto newElement = new ImgElementGui;
        auto elements = cast(ImgElementGui[])getList();
        auto id = selected();

        if(elements.length == 0u) {
            return;
        }

        newElement.label.text = elements[id].label.text;
        newElement.data.type = elements[id].data.type;
        newElement.data.clip = elements[id].data.clip;
        newElement.data.columns = elements[id].data.columns;
        newElement.data.lines = elements[id].data.lines;
        newElement.data.maxtiles = elements[id].data.maxtiles;
        newElement.data.top = elements[id].data.top;
        newElement.data.bottom = elements[id].data.bottom;
        newElement.data.left = elements[id].data.left;
        newElement.data.right = elements[id].data.right;

        if(id >= elements.length)
            throw new Exception("Element id out of bounds");
        else if(id + 1 == elements.length) {
            elements ~= newElement;
        }
        else if(id == 0u) {
            elements = [elements[0], newElement] ~ elements[1..$];
        }
        else {
            elements = elements[0..id] ~ newElement ~ elements[id..$];
        }

        removeChildrenGuis();
        foreach(element; elements)
            addChildGui(element);
        selected(id + 1);

        setElements();
        triggerCallback();
    }

    void removeElement() {
		auto elements = getList();
        auto id = selected();

        if(!elements.length)
            return;

		if(id >= elements.length)
			throw new Exception("Element id out of bounds");
		else if(id + 1 == elements.length) {
			elements.length --;
            id --;
        }
		else if(id == 0u) {
			elements = elements[1..$];
            id = 0u;
        }
		else {
			elements = elements[0..id] ~ elements[id + 1..$];
            id --;
        }

		removeChildrenGuis();
		foreach(element; elements)
			addChildGui(element);
        if(elements.length)
            selected(id);

        setElements();
        triggerCallback();
    }

    ElementData getSelectedData() {
        auto elements = getList();
        auto id = selected();

        if(!elements.length || id >= elements.length)
            throw new Exception("No image element selected");
        return (cast(ImgElementGui)elements[id]).data;
    }

    void setElements() {
        ElementData[] elements;
		foreach(ImgElementGui elementGui; cast(ImgElementGui[])getList()) {
            elements ~= elementGui.data;
        }
        setCurrentElements(elements);
    }

    bool isSelectingData() {
        const auto elements = getList();
        const auto id = selected();

        return (elements.length && id < elements.length);
    }

    void reload() {
        removeChildrenGuis();

        auto tabData = getCurrentTab();
		foreach(ElementData element; tabData.elements) {
            auto elementGui = new ImgElementGui;
            elementGui.data = element;
            elementGui.label.text = element.name;
            addChildGui(elementGui);
        }
        triggerCallback();
    }
}