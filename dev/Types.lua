--!strict
--Licensed from @dphfox/tokamak under MIT

export type GraphObject = {
	type: "GraphObject",
	name: string,
	valid: boolean,
	lastVisibleDifference: number?,
	validator: () -> boolean,
	using: {[GraphObject]: true},
	users: {[GraphObject]: true},

	use: (
		self: GraphObject,
		upstream: GraphObject
	) -> (),
	unuseAll: (
		self: GraphObject
	) -> (),
	invalidate: (
		self: GraphObject
	) -> (),
	validate: (
		self: GraphObject
	) -> (),
	destroy: (
		self: GraphObject
	) -> ()
}

export type StateObject<T> = {
	type: "StateObject",
	name: string,
	graph: GraphObject,

	peek: (
		self: StateObject<T>
	) -> T,
	destroy: (
		self: StateObject<T>
	) -> ()
}

export type CanBeState<T> = StateObject<T> | T

-- The `| T` must go afterwards, or else the Luau Gods will smite you.
export type Use = <T>(CanBeState<T>) -> T

export type Value<R, W = R> = StateObject<R | W> & {
	value: W,

	set: (
		self: Value<R, W>,
		newValue: W
	) -> ()
}

export type Computed<T> = StateObject<T> & {
	processor: (Use) -> T,
	cachedValue: T?,
	useCallback: Use
}

return nil