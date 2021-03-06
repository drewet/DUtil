/*
Copyright (c) 2010-2011 Pavel Sountsov

This software is provided 'as-is', without any express or implied
warranty. In no event will the authors be held liable for any damages
arising from the use of this software.

Permission is granted to anyone to use this software for any purpose,
including commercial applications, and to alter it and redistribute it
freely, subject to the following restrictions:

   1. The origin of this software must not be misrepresented; you must not
   claim that you wrote the original software. If you use this software
   in a product, an acknowledgment in the product documentation would be
   appreciated but is not required.

   2. Altered source versions must be plainly marked as such, and must not be
   misrepresented as being the original software.

   3. This notice may not be removed or altered from any source
   distribution.
*/

/**
 * D1 only.
 * 
 * A set of functions that work on arrays.
 */

module dutil.ArrayMath;

import math = tango.math.Math;

T[] zip(alias func, T)(T[] arr, T[] ret = null)
{
	assert(arr.length);
	
	if(ret is null)
		ret.length = arr.length - 1;
	else
		assert(ret.length == arr.length - 1);

	T temp = arr[0];
	foreach(ii, elem; arr[1..$])
	{
		ret[ii] = cast(T)func(temp, elem);
		temp = elem;
	}
	
	return ret;
}

T reduce(alias func, T)(T[] arr)
{
	assert(arr.length);
	T ret = arr[0];
	foreach(elem; arr[1..$])
		ret = cast(T)func(ret, elem);
	return ret;
}

T[] map(alias func, T)(T[] arr, T[] ret = null)
{
	if(ret is null)
		ret.length = arr.length;
	else
		assert(ret.length == arr.length);

	foreach(ii, elem; arr)
		ret[ii] = cast(T)func(elem);
	
	return ret;
}

private template map_fun(const(char)[] ar_fun_name, const(char)[] fun_name)
{
	enum map_fun = 
"T[] " ~ ar_fun_name ~ "(T)(T[] arr, T[] ret = null)
{
	return map!(" ~ fun_name ~ ")(arr, ret);
}";
}

private template reduce_fun(const(char)[] ar_fun_name, const(char)[] fun_name)
{
	enum reduce_fun = 
"T " ~ ar_fun_name ~ "(T)(T[] arr)
{
	return reduce!(" ~ fun_name ~ ")(arr);
}";
}

private template zip_fun(const(char)[] ar_fun_name, const(char)[] fun_name)
{
	enum zip_fun = 
"T[] " ~ ar_fun_name ~ "(T)(T[] arr, T[] ret = null)
{
	return zip!(" ~ fun_name ~ ")(arr, ret);
}";
}

mixin(map_fun!("sin", "math.sin"));
mixin(map_fun!("cos", "math.cos"));
mixin(map_fun!("abs", "math.abs"));
mixin(map_fun!("sqrt", "math.sqrt"));
mixin(map_fun!("exp", "math.exp"));

T[] convolve(T)(T[] arr, T[] filter, T[] ret = null)
{
	assert(filter.length > 0, "Must have a non-empty filter");
	assert(arr.length >= filter.length, "Array length must be greater than the filter length");
	
	ret.length = arr.length - filter.length + 1;
		
	foreach(r_idx, ref r; ret)
	{
		r = 0;
		foreach(f_idx, f; filter)
		{
			r += f * arr[r_idx + f_idx];
		}
	}
	
	return ret;
}

T[] running_average(T)(T[] arr, size_t run_length, T[] ret = null)
{
	scope T[] filter = new T[](run_length);
	filter[] = cast(T)(1.0 / run_length);
	return convolve(arr, filter, ret);
}

T[] pow(T)(T[] arr, T power, T[] ret = null)
{
	return map!((T a) {return math.pow(a, power);})(arr, ret);
}

private T sum_f(T)(T a, T b)
{
	return a + b;
}

private T product_f(T)(T a, T b)
{
	return a * b;
}

mixin(reduce_fun!("min", "math.min!(T, T)"));
mixin(reduce_fun!("max", "math.max!(T, T)"));
mixin(reduce_fun!("sum", "sum_f!(T)"));
mixin(reduce_fun!("product", "product_f!(T)"));

T dot(T)(T[] arr1, T[] arr2)
{
	T ret = cast(T)0;
	foreach(idx, v1; arr1)
		ret += v1 * arr2[idx];

	return ret;
}

T mag_squared(T)(T[] arr)
{
	T ret = cast(T)0;
	foreach(v; arr)
		ret += v * v;

	return ret;
}

T mag(T)(T[] arr)
{
	return math.sqrt(mag_squared(arr));
}

private T diff_f(T)(T a, T b)
{
	return b - a;
}

mixin(zip_fun!("diff", "diff_f!(T)"));

T mean(T)(T[] arr)
{
	auto s = arr.sum();
	return s / arr.length;
}

T std(T)(T[] arr)
{
	assert(arr.length > 1, "std(): Array needs to have at least 2 elements.");
	T a = 0;
	T m = arr.mean();
	foreach(elem; arr)
	{
		a += (elem - m) * (elem - m);
	}
	return math.sqrt(cast(real)(a / arr.length));
}

T kurtosis(T)(T[] arr)
{
	assert(arr.length > 1, "kurtosis(): Array needs to have at least 2 elements.");
	T s2 = 0;
	T s4 = 0;
	T m = arr.mean();
	foreach(elem; arr)
	{
		s2 += (elem - m) * (elem - m);
		s4 += math.pow(cast(real)(elem - m), 4.0);
	}
	s4 /= arr.length;
	s2 /= arr.length;
	
	return s4 / (s2 * s2) - 3;
}
