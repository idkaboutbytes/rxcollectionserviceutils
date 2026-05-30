
--[=[
	@class RxCollectionServiceUtils
]=]

const CollectionService = game:GetService('CollectionService')

const Brio = require('@game/ReplicatedStorage/Packages/.pesde/idkaboutbytes+brio/1.2.1/src')
const Maid = require('@game/ReplicatedStorage/Packages/.pesde/idkaboutbytes+maid/1.1.1/src')
const Observable = require('@game/ReplicatedStorage/Packages/.pesde/idkaboutbytes+observable/1.0.1/src')

const RxCollectionServiceUtils = {}

--[=[
	Observes tagged instances

	@param tagName string
	@return Observable<Brio<Instance>>
]=]
@checked
function RxCollectionServiceUtils.observeTaggedBrio(tagName: string): Observable.Observable<Brio.Brio<Instance>>
	assert(type(tagName) == 'string', 'Bad tagName')

	return Observable.new(function(sub)
		local maid = Maid.new()

		local function handleItemAdded(inst)
			local brio = Brio.new(inst)
			maid[inst] = brio
			sub:Fire(brio)
		end

		maid:GiveTask(CollectionService:GetInstanceAddedSignal(tagName):Connect(handleItemAdded))
		maid:GiveTask(CollectionService:GetInstanceRemovedSignal(tagName):Connect(function(inst)
			maid[inst] = nil
		end))

		for _, inst in CollectionService:GetTagged(tagName) do
			task.spawn(handleItemAdded, inst)
		end

		return maid
	end)
end

--[=[
	Observes tagged instances without a brio (so just when the item is added or on-init

	@param tagName string
	@return Observable<Instance>
]=]
@checked
function RxCollectionServiceUtils.observeTagged(tagName: string): Observable.Observable<Instance>
	assert(type(tagName) == 'string', 'Bad tagName')

	return Observable.new(function(sub)
		local maid = Maid.new()

		local function handleItemAdded(inst: Instance)
			sub:Fire(inst)
		end

		maid:GiveTask(CollectionService:GetInstanceAddedSignal(tagName):Connect(handleItemAdded))

		for _, inst in CollectionService:GetTagged(tagName) do
			task.spawn(handleItemAdded, inst)
		end

		return maid
	end) :: any
end

--[=[
	Observes tagged instances as a list that re-emits. Reuses the same list. O(n^2) operations.

	@param tagName string
	@return Observable<{ Instance }>
]=]
@checked
function RxCollectionServiceUtils.observeTaggedList(tagName: string): Observable.Observable<{ Instance }>
	assert(type(tagName) == 'string', 'Bad tagName')

	return Observable.new(function(sub)
		local maid = Maid.new()

		local list = CollectionService:GetTagged(tagName)

		maid:GiveTask(CollectionService:GetInstanceAddedSignal(tagName):Connect(function(item)
			table.insert(list, item)

			sub:Fire(list)
		end))

		maid:GiveTask(CollectionService:GetInstanceRemovedSignal(tagName):Connect(function(item)
			local index = table.find(list, item)
			if index then
				table.remove(list, index)
			end

			sub:Fire(list)
		end))

		sub:Fire(list)

		return maid
	end)
end

return RxCollectionServiceUtils
